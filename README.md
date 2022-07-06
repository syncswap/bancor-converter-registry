# Bancor Converter Registry

The bancor converter registry keeps converter addresses by token addresses and vice versa.

The owner can update converter addresses so that a the token address always points to the updated list of converters for each token.

The contract also allows to iterate through all the tokens in the network.

Note that converter addresses for each token are returned in ascending order (from oldest to latest).
