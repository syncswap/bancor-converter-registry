// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

/*
    Owned contract interface
*/
interface IOwned {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;
    function acceptOwnership() external;
}

/*
    Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public override owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
        @dev constructor
    */
    constructor() {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

    /**
        @dev allows transferring the contract ownership
        the new owner still needs to accept the transfer
        can only be called by the contract owner

        @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly override {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
        @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public override {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

/*
    Utilities & Common Modifiers
*/
contract Utils {
    /**
        constructor
    */
    constructor() {
    }

    // verifies that an amount is greater than zero
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

}

/**
    Bancor Converter Registry

    The bancor converter registry keeps converter addresses by token addresses and vice versa.
    The owner can update converter addresses so that a the token address always points to
    the updated list of converters for each token.

    The contract also allows to iterate through all the tokens in the network.

    Note that converter addresses for each token are returned in ascending order (from oldest
    to latest).
*/
contract BancorConverterRegistry is Owned, Utils {
    mapping (address => bool) private tokensRegistered;         // token address -> registered or not
    mapping (address => address[]) private tokensToConverters;  // token address -> converter addresses
    mapping (address => address) private convertersToTokens;    // converter address -> token address
    address[] public tokens;                                    // list of all token addresses

    // triggered when a converter is added to the registry
    event ConverterAddition(address indexed _token, address _address);

    // triggered when a converter is removed from the registry
    event ConverterRemoval(address indexed _token, address _address);

    /**
        @dev constructor
    */
    constructor() {
    }

    /**
        @dev returns the number of tokens in the registry

        @return number of tokens
    */
    function tokenCount() public view returns (uint256) {
        return tokens.length;
    }

    /**
        @dev returns the number of converters associated with the given token
        or 0 if the token isn't registered

        @param _token   token address

        @return number of converters
    */
    function converterCount(address _token) public view returns (uint256) {
        return tokensToConverters[_token].length;
    }

    /**
        @dev returns the converter address associated with the given token
        or zero address if no such converter exists

        @param _token   token address
        @param _index   converter index

        @return converter address
    */
    function converterAddress(address _token, uint32 _index) public view returns (address) {
        if (_index >= tokensToConverters[_token].length)
            return address(0);

        return tokensToConverters[_token][_index];
    }

    /**
        @dev returns the token address associated with the given converter
        or zero address if no such converter exists

        @param _converter   converter address

        @return token address
    */
    function tokenAddress(address _converter) public view returns (address) {
        return convertersToTokens[_converter];
    }

    /**
        @dev adds a new converter address for a given token to the registry
        throws if the converter is already registered

        @param _token       token address
        @param _converter   converter address
    */
    function registerConverter(address _token, address _converter)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_converter)
    {
        require(convertersToTokens[_converter] == address(0));

        // add the token to the list of tokens
        if (!tokensRegistered[_token]) {
            tokens.push(_token);
            tokensRegistered[_token] = true;
        }

        tokensToConverters[_token].push(_converter);
        convertersToTokens[_converter] = _token;

        // dispatch the converter addition event
        emit ConverterAddition(_token, _converter);
    }

    /**
        @dev removes an existing converter from the registry
        note that the function doesn't scale and might be needed to be called
        multiple times when removing an older converter from a large converter list

        @param _token   token address
        @param _index   converter index
    */
    function unregisterConverter(address _token, uint32 _index)
        public
        ownerOnly
        validAddress(_token)
    {
        uint256 _tokensToConvertersTokensLength = tokensToConverters[_token].length;
        require(_index < _tokensToConvertersTokensLength);

        address converter = tokensToConverters[_token][_index];

        // move all newer converters 1 position lower
        for (uint32 i = _index + 1; i < _tokensToConvertersTokensLength; ) {
            tokensToConverters[_token][i - 1] = tokensToConverters[_token][i];
            unchecked { ++i; }
        }

        // decrease the number of converters defined for the token by 1
        tokensToConverters[_token].pop();
        
        // removes the converter from the converters -> tokens list
        delete convertersToTokens[converter];

        // dispatch the converter removal event
        emit ConverterRemoval(_token, converter);
    }
}