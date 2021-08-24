//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IAuctionSea {
    function placeBid(uint256 _nftId) external payable;

    function auction(uint256)
        external
        view
        returns (
            uint256,
            uint256,
            address,
            address,
            bool
        );
}
