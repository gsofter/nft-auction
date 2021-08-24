//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IMoldNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AuctionSea is Ownable {
    struct Auction {
        uint256 highestBid;
        uint256 closingTime;
        address highestBidder;
        address originalOwner;
        bool isActive;
    }

    // NFT id => Auction data
    mapping(uint256 => Auction) public auctions;

    // MoldNFT contract interface
    IMoldNFT private sNft_;

    // ETH balance
    uint256 public balances;
    uint256 public gasPrice;

    event NewAuctionOpened(
        uint256 nftId,
        uint256 startingBid,
        uint256 closingTime,
        address originalOwner
    );

    event AuctionClosed(
        uint256 nftId,
        uint256 highestBid,
        address highestBidder
    );

    event BidPlaced(uint256 nftId, uint256 bidPrice, address bidder);

    /**
     * @dev Receive ETH. msg.data is empty
     */
    receive() external payable {
        balances += msg.value;
    }

    /**
     * @dev Receive ETH. msg.data is not empty
     */
    fallback() external payable {
        balances += msg.value;
    }

    /**
     * @dev Initialize states
     * @param _sNft MoldNFT contract address
     */
    function initialize(address _sNft) external onlyOwner {
        require(_sNft != address(0), "Invalid address");

        sNft_ = IMoldNFT(_sNft);

        balances = 0;
        gasPrice = 2500;
    }

    /**
     * @dev Set gas price
     * @param _gasPrice gas price
     */
    function setGasPrice(uint256 _gasPrice) external onlyOwner {
        gasPrice = _gasPrice;
    }

    /**
     * @dev Open Auction
     * @param _nftId NFT id
     * @param _sBid Starting bid price
     * @param _duration Auction opening duration time
     */
    function openAuction(
        uint256 _nftId,
        uint256 _sBid,
        uint256 _duration
    ) external {
        require(auctions[_nftId].isActive == false, "Ongoing auction detected");
        require(_duration > 0 && _sBid > 0, "Invalid input");
        require(sNft_.ownerOf(_nftId) == msg.sender, "Not NFT owner");

        // NFT Transfer to contract
        sNft_.transfer(_nftId, address(this));

        // Opening new auction
        auctions[_nftId].highestBid = _sBid;
        auctions[_nftId].closingTime = block.timestamp + _duration;
        auctions[_nftId].highestBidder = msg.sender;
        auctions[_nftId].originalOwner = msg.sender;
        auctions[_nftId].isActive = true;

        emit NewAuctionOpened(
            _nftId,
            auctions[_nftId].highestBid,
            auctions[_nftId].closingTime,
            auctions[_nftId].highestBidder
        );
    }

    /**
     * @dev Place Bid
     * @param _nftId NFT id
     */
    function placeBid(uint256 _nftId) external payable {
        require(auctions[_nftId].isActive == true, "Not active auction");
        require(
            auctions[_nftId].closingTime > block.timestamp,
            "Auction is closed"
        );
        require(msg.value > auctions[_nftId].highestBid, "Bid is too low");

        if (auctions[_nftId].originalOwner != auctions[_nftId].highestBidder) {
            // Transfer ETH to Previous Highest Bidder
            (bool sent, ) = payable(auctions[_nftId].highestBidder).call{
                value: auctions[_nftId].highestBid
            }("");

            require(sent, "Transfer ETH failed");
        }

        auctions[_nftId].highestBid = msg.value;
        auctions[_nftId].highestBidder = msg.sender;

        emit BidPlaced(
            _nftId,
            auctions[_nftId].highestBid,
            auctions[_nftId].highestBidder
        );
    }

    /**
     * @dev Close Auction
     * @param _nftId NFT id
     */
    function closeAuction(uint256 _nftId) external {
        require(auctions[_nftId].isActive == true, "Not active auction");
        require(
            auctions[_nftId].closingTime <= block.timestamp,
            "Auction is not closed"
        );

        // Transfer ETH to NFT Owner
        if (auctions[_nftId].originalOwner != auctions[_nftId].highestBidder) {
            (bool sent, ) = payable(auctions[_nftId].originalOwner).call{
                value: auctions[_nftId].highestBid
            }("");

            require(sent, "Transfer ETH failed");
        }

        // Transfer NFT to Highest Bidder
        sNft_.transfer(_nftId, auctions[_nftId].highestBidder);

        // Close Auction
        auctions[_nftId].isActive = false;

        emit AuctionClosed(
            _nftId,
            auctions[_nftId].highestBid,
            auctions[_nftId].highestBidder
        );
    }

    /**
     * @dev Withdraw ETH
     * @param _target Spender address
     * @param _amount Transfer amount
     */
    function withdraw(address _target, uint256 _amount) external onlyOwner {
        require(_target != address(0), "Invalid address");
        require(_amount > 0 && _amount < balances, "Invalid amount");

        payable(_target).transfer(_amount);

        balances = balances - _amount;
    }
}
