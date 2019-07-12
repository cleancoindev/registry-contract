/*

  Copyright 2019 Microsponsors, Inc.
  This work has been modified for use by Microsponsors, Inc.
  This derivative work is licensed under the Apache License, Version 2.0
  Original license notice below:

  Copyright 2018 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.5;
pragma experimental ABIEncoderV2;

import "./IExchange.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibOrder.sol";
import "@0x/contracts-utils/contracts/src/Ownable.sol";


contract Whitelist is
    Ownable
{

    // Microsponsors Registry Data:

    // Mapping of address => whitelist status.
    mapping (address => bool) public isWhitelisted;

    // Mapping of contentId => address
    mapping (string => address) private contentIdToAddress;

    // Mapping of address => array of ContentId structs
    struct ContentId {
        string contentId;
    }
    mapping (address => ContentId[]) private addressToContentIds;


    // Exchange contract.
    // solhint-disable var-name-mixedcase
    IExchange internal EXCHANGE;
    bytes internal TX_ORIGIN_SIGNATURE;
    // solhint-enable var-name-mixedcase

    byte constant internal VALIDATOR_SIGNATURE_BYTE = "\x05";

    constructor (address _exchange)
        public
    {
        EXCHANGE = IExchange(_exchange);
        TX_ORIGIN_SIGNATURE = abi.encodePacked(address(this), VALIDATOR_SIGNATURE_BYTE);
    }

    /// @dev Admin adds or remove an address & domain mapping from the whitelist.
    /// @param target Address to add or remove from whitelist.
    /// @param contentId To map to ethereum address to.
    /// @param isApproved Whitelist status to assign to address.
    function adminUpdateWhitelist(
        address target,
        string calldata contentId,
        bool isApproved
    )
        external
        onlyOwner
    {

        // Check that content id is not a duplicate for this owner
        if (contentIdToAddress[contentId] != target) {

            addressToContentIds[target].push(ContentId(contentId));
            contentIdToAddress[contentId] = target;

        }

        isWhitelisted[target] = isApproved;

    }


    /// @dev Admin updates whitelist status for a given address.
    /// @param target Address to add or remove from Whitelist.
    /// @param isApproved Whitelist status to assign to address.
    function adminUpdateStatus(
        address target,
        bool isApproved
    )
        external
        onlyOwner
    {

        require(
          addressToContentIds[target].length > 0,
          'ADDRESS_HAS_NO_ASSOCIATED_CONTENT_IDS'
        );

        isWhitelisted[target] = isApproved;

    }


    function adminGetAddressByContentId(
        string calldata contentId
    )
        external
        view
        onlyOwner
        returns (address target)
    {

        require(
            isWhitelisted[ contentIdToAddress[contentId] ],
            "ADDRESS_NOT_WHITELISTED"
        );

        return contentIdToAddress[contentId];

    }


    /// @dev Admin gets contentIds mapped to a valid whitelisted address.
    /// @param target Ethereum address to validate & return contentIds for.
    function adminGetContentIdsByAddress(
        address target
    )
        external
        view
        onlyOwner
        returns (ContentId[] memory)
    {

        require(
            isWhitelisted[target],
            "ADDRESS_NOT_WHITELISTED"
        );

        return addressToContentIds[target];

    }


    /// @dev Valid whitelisted address can query its own contentIds.
    function getContentIdsByAddress()
        external
        view
        returns (ContentId[] memory)
    {

        require(
            isWhitelisted[msg.sender],
            'INVALID_SENDER'
        );

        return addressToContentIds[msg.sender];

    }


    /// @dev Verifies signer is same as signer of current Ethereum transaction.
    ///      NOTE: This function can currently be used to validate signatures coming from outside of this contract.
    ///      Extra safety checks can be added for a production contract.
    /// @param signerAddress Address that should have signed the given hash.
    /// @param signature Proof of signing.
    /// @return Validity of order signature.
    // solhint-disable no-unused-vars
    function isValidSignature(
        bytes32 hash,
        address signerAddress,
        bytes calldata signature
    )
        external
        view
        returns (bool isValid)
    {
        // solhint-disable-next-line avoid-tx-origin
        return signerAddress == tx.origin;
    }
    // solhint-enable no-unused-vars

    /// @dev Fills an order using `msg.sender` as the taker.
    ///      The transaction will revert if both the maker and taker are not whitelisted.
    ///      Orders should specify this contract as the `senderAddress` in order to gaurantee
    ///      that both maker and taker have been whitelisted.
    /// @param order Order struct containing order specifications.
    /// @param takerAssetFillAmount Desired amount of takerAsset to sell.
    /// @param salt Arbitrary value to gaurantee uniqueness of 0x transaction hash.
    /// @param orderSignature Proof that order has been created by maker.
    function fillOrderIfWhitelisted(
        LibOrder.Order memory order,
        uint256 takerAssetFillAmount,
        uint256 salt,
        bytes memory orderSignature
    )
        public
    {
        address takerAddress = msg.sender;

        // This contract must be the entry point for the transaction.
        require(
            // solhint-disable-next-line avoid-tx-origin
            takerAddress == tx.origin,
            "INVALID_SENDER"
        );

        // Check if maker is on the whitelist.
        require(
            isWhitelisted[order.makerAddress],
            "MAKER_NOT_WHITELISTED"
        );

        // Check if taker is on the whitelist.
        require(
            isWhitelisted[takerAddress],
            "TAKER_NOT_WHITELISTED"
        );

        // Encode arguments into byte array.
        bytes memory data = abi.encodeWithSelector(
            EXCHANGE.fillOrder.selector,
            order,
            takerAssetFillAmount,
            orderSignature
        );

        // Call `fillOrder` via `executeTransaction`.
        EXCHANGE.executeTransaction(
            salt,
            takerAddress,
            data,
            TX_ORIGIN_SIGNATURE
        );
    }
}
