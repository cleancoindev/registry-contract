/*

  Copyright 2019 Niche Networks, Inc. (owns & operates Microsponsors.io)
  This work has been modified for use by Microsponsors.io
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


    /***  Microsponsors Registry Data:  ***/


    // Array of registrant addresses
    // Regardless of isWhitelisted status
    address[] private registrants;

    // Map address => whitelist status.
    // Addresses authorized to transact thru this Registry.
    mapping (address => bool) public isWhitelisted;

    // Map address => array of ContentId structs.
    // Using struct because there is no mapping to an array of strings in solidity at this time.
    struct ContentIdStruct {
        string contentId;
    }
    mapping (address => ContentIdStruct[]) private addressToContentIds;

    // Pause. When true, Registry state updates and 0x order fills are blocked.
    bool public paused = false;


    /***  0x Exchange Details:  ***/


    // 0x Exchange contract.
    // solhint-disable var-name-mixedcase
    IExchange internal EXCHANGE;
    bytes internal TX_ORIGIN_SIGNATURE;
    // solhint-enable var-name-mixedcase

    byte constant internal VALIDATOR_SIGNATURE_BYTE = "\x05";


    /***  Constructor  ***/

    /// @param _exchange 0x Exchange contract address to direct order fills to
    constructor (address _exchange)
        public
    {
        EXCHANGE = IExchange(_exchange);
        TX_ORIGIN_SIGNATURE = abi.encodePacked(address(this), VALIDATOR_SIGNATURE_BYTE);
    }


    /***  Admin functions (onlyOwner) that mutate contract state  ***/


    /// @dev Admin registers an address with a contentId.
    /// @param target Address to add or remove from whitelist.
    /// @param contentId UTF8 string that is hex-encoded
    /// @param isApproved Whitelist status to assign to the address.
    function adminUpdate(
        address target,
        string calldata contentId,
        bool isApproved
    )
        external
        onlyOwner
        whenNotPaused
    {

        // TODO: disallow duplicates!
        // TODO: if contentId was previously assigned to another address
        //       and we remove that addresses last contentId here,
        //       we have to remove that address from the whitelist, too
        // Assign content id to registrant address
        addressToContentIds[target].push( ContentIdStruct(contentId) );

        if (!hasRegistered(target)) {
            registrants.push(target);
        }

        isWhitelisted[target] = isApproved;

    }


    /// @dev Admin updates whitelist status for a given address.
    /// @param target Address to update.
    /// @param isApproved Whitelist status to assign to address.
    function adminUpdateWhitelistStatus(
        address target,
        bool isApproved
    )
        external
        onlyOwner
        whenNotPaused
    {

        // Revert transaction (refund gas) if
        // the requested whitelist status update is redundant
        require(
            isApproved != isWhitelisted[target],
            'NO_STATUS_UPDATE_REQUIRED'
        );

        // Disallow users with no associated content ids
        // (ex: admin or user themselves may have removed content ids)
        if (isApproved == true) {
            require(
                getNumContentIds(target) > 0,
                'ADDRESS_HAS_NO_ASSOCIATED_CONTENT_IDS'
            );
        }

        isWhitelisted[target] = isApproved;

    }

    /// @dev Admin removes a contentId from a given address.
    function adminRemoveContentIdFromAddress(
        address target,
        string calldata contentId
    )
        external
        onlyOwner
        whenNotPaused
    {

        // Remove content id from addressToContentIds mapping
        ContentIdStruct[] memory m = addressToContentIds[target];
        for (uint i = 0; i < m.length; i++) {
            if (stringsMatch(contentId, m[i].contentId)) {
                addressToContentIds[target][i] = ContentIdStruct('');
            }
        }

        // If address has no valid content ids left, remove from Whitelist.
        if (getNumContentIds(target) == 0) {
            isWhitelisted[target] = false;
        }

    }


    /*** Admin read-only functions ***/


    function adminGetRegistrantCount ()
        external
        view
        onlyOwner
        returns (uint)
    {

        return registrants.length;

    }

    function adminGetRegistrantByIndex (
        uint index
    )
        external
        view
        onlyOwner
        returns (address)
    {

        // Will throw error if specified index does not exist
        return registrants[index];

    }


    function adminGetAddressByContentId(
        string calldata contentId
    )
        external
        view
        onlyOwner
        returns (address target)
    {

        // TODO update me; loop thru addressToContent id instead
        // return contentIdToAddress[contentId];

    }


    /// @dev Admin gets contentIds mapped to a valid whitelisted address.
    /// @param target Ethereum address to validate & return contentIds for.
    function adminGetContentIdsByAddress(
        address target
    )
        external
        view
        onlyOwner
        returns (string[] memory)
    {

        ContentIdStruct[] memory m = addressToContentIds[target];
        string[] memory r = new string[](m.length);

        for (uint i = 0; i < m.length; i++) {
            r[i] =  m[i].contentId;
        }

        return r;

    }


    /*** User-facing functions ***/


    /// @dev Valid whitelisted address can query its own contentIds.
    function getContentIdsByAddress()
        external
        view
        returns (string[] memory)
    {

        require(
            isWhitelisted[msg.sender],
            'INVALID_SENDER'
        );

        ContentIdStruct[] memory m = addressToContentIds[msg.sender];
        string[] memory r = new string[](m.length);

        for (uint i = 0; i < m.length; i++) {
            r[i] =  m[i].contentId;
        }

        return r;

    }


    /// @dev Valid whitelisted address can remove its own content id.
    function removeContentIdFromAddress(
        string calldata contentId
    )
        external
        whenNotPaused
    {

        require(
            isWhitelisted[msg.sender],
            'INVALID_SENDER'
        );

        require(
            // TODO update me:
            // contentIdToAddress[contentId] == msg.sender,
            'CONTENT_ID_DOES_NOT_BELONG_TO_SENDER'
        );

        // Remove content id from addressToContentIds mapping
        // (Simply replace content id with empty string)
        ContentIdStruct[] memory m = addressToContentIds[msg.sender];
        for (uint i = 0; i < m.length; i++) {
            if (stringsMatch(contentId, m[i].contentId)) {
                addressToContentIds[msg.sender][i] = ContentIdStruct('');
            }
        }

        // If address has no valid content ids left, remove from Whitelist
        if (getNumContentIds(msg.sender) == 0) {
            isWhitelisted[msg.sender] = false;
        }

    }


    /*** Transaction validation & Execution ***/


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
        whenNotPaused
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


    /*** Pausable adapted from OpenZeppelin via Cryptokitties ***/


    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by contract owner to pause actions on this contract
    function pause() external onlyOwner whenNotPaused {
        paused = true;
    }

    /// @dev Called by contract owner to unpause the smart contract.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyOwner whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }


    /***  Helpers  ***/


    function hasRegistered (
        address target
    )
        public
        view
        returns(bool)
    {

        bool hasRegistered = false;
        for (uint i=0; i<registrants.length; i++) {
            if (registrants[i] == target) {
                return hasRegistered = true;
            }
        }

    }


    function stringsMatch (
        string memory a,
        string memory b
    )
        private
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))) );
    }


    function getNumContentIds (
        address target
    )
        private
        view
        returns (uint16)
    {

        ContentIdStruct[] memory m = addressToContentIds[target];
        uint16 counter = 0;
        for (uint i = 0; i < m.length; i++) {
            // Omit entries that are empty strings
            // (from contentIds that were removed)
            if (!stringsMatch('', m[i].contentId)) {
                counter++;
            }
        }

        return counter;

    }


}
