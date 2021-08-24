// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAuctionSea.sol";

contract MultiSig is Ownable {
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event ConfirmBid(address indexed owner, uint256 indexed _nftId);
    event PlaceBid(uint256 indexed _nftId, uint256 bidPrice);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    IAuctionSea auction_;

    // nftId => address => confirmed
    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    mapping(uint256 => uint256) public confirmations;

    modifier onlyMember() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier notConfirmed(uint256 _nftId) {
        require(!isConfirmed[_nftId][msg.sender], "already confirmed");
        _;
    }

    function initialize(
        address auctionAddress,
        address[] memory _owners,
        uint256 _numConfirmations
    ) external onlyOwner {
        require(auctionAddress != address(0), "Invalid address");
        require(
            _numConfirmations > 0 && _numConfirmations <= _owners.length,
            "invalid number of required confirmations"
        );
        auction_ = IAuctionSea(auctionAddress);

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmations;
    }

    function setOwners(address[] memory _owners) external onlyOwner {
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
    }

    function setNumConfirmationsRequired(uint256 _numConfirmations)
        external
        onlyOwner
    {
        require(
            _numConfirmations > 0 && _numConfirmations <= owners.length,
            "invalid number of required confirmations"
        );
        numConfirmationsRequired = _numConfirmations;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function placeBid(uint256 _nftId) public onlyMember {
        (uint256 highestBid, , , , ) = auction_.auction(_nftId);
        uint256 bidPrice = highestBid + 10**14;
        require(address(this).balance >= bidPrice, "Not sufficient amount");
        auction_.placeBid{value: bidPrice}(_nftId);
        emit PlaceBid(_nftId, bidPrice);
    }

    function confirmBid(uint256 _nftId) public onlyMember notConfirmed(_nftId) {
        confirmations[_nftId] += 1;
        isConfirmed[_nftId][msg.sender] = true;
        if (confirmations[_nftId] >= numConfirmationsRequired) {
            placeBid(_nftId);
        }
        emit ConfirmBid(msg.sender, _nftId);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }
}
