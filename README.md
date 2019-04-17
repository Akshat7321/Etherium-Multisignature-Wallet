# Etherium-Multisignature-Wallet
FOSSEE submission


This is a Smart Contract implementing the concept of Multisignature Wallet.
One can add ether to it.

Request for transactions.

Any request has to be verified by atleast n users controlling the wallet hence it is also called n of m (n<=m)Wallet.
It can work out the transactions according to the decisions made by the wallet Controllers

After its implementation one can expand or reduce the size of wallet controllers

Further, the ModifiedSmartContract has new feature which allows user to set the weights of different controllers
Thus, every transaction passes with votes distributed as per the weights of the users.

dependencies:

1: Node

2: Truffle

3: Ganache(for private chain deployment)


INSTRUCTIONS TO USE THE MULTIIG WALLET:

1: Deploy the wallet by passing  some initial Signers (their account addresses on Etherium network), the threshold number of verifications to confirm the transaction and their weights(if required).

2: Now Submit Transactions ---> Sign transaction as per the index ---> Call the Complete Transaction method which automatically checks for the threshold number of signs on transactions and then executes the transaction if the signs cross the threshold value.

3: One can remove a previous owner and can add a new owner as per the requirements by calling the request controller functions.

4: Note that at a time only one request can be generated and executed. To pass these requests or cancel any request the  request should be accepted by all the Wallet Controllers at that time irrespective of their weights(if any).
