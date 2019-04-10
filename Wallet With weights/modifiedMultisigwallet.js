const ModifiedMultisigwallet = artifacts.require('ModifiedMultisigwallet')
const assert = require('assert')

const deployMultisig = (owners, confirmations,weights) => {
    return ModifiedMultisigwallet.new(owners, confirmations, weights)
}
let contractInstance

contract('ModifiedMultisigwallet', (accounts) => {

	it('Should create a wallet with 0 balance initially and 2 signers',function () {	
		return deployMultisig([accounts[0],accounts[1]],[0,3],2).then(function(instance){
			contractInstance = instance;
			return contractInstance.Showbalance()
		}).then(function(result){
			var a=result.toNumber();
			// checking if the wallet has 0 as balance
			assert.equal(a,0);

			// checking for the signers 
			// both the signers have been assigned
			// we have selected account[0] and account[1] as signers
			var signer1= contractInstance.signers(0);
			//var signer2= contractInstance.signers(1);
			return signer1;
		}).then(function(result){
			assert.equal(result, accounts[0])
		}).then(function(){
			var signer2= contractInstance.signers(1);
			return signer2;
		}).then(function(result){
			assert.equal(result, accounts[1])
			console.log("Wallet created succesfuly with  2 signers(account[0] and account[1] respecively)");
		}).then(function(){
			//assert.equal(result, accounts[1])
			var balanceAccount1=web3.eth.getBalance(accounts[0]);
			return balanceAccount1;
		}).then(function(result){
			console.log("Balance of account 1:"+result);
		}).then(function(){
			//assert.equal(result, accounts[1])
			var balanceAccount2=web3.eth.getBalance(accounts[1]);
			return balanceAccount2;
		}).then(function(result){
			console.log("Balance of account 2:"+result);
		});
	
	})


	it("Submitting a transaction", function(){
		return deployMultisig([accounts[0], accounts[1]],[0,3],2).then(function(instance){
	 	contractInstance= instance;
	 	return contractInstance.submitTransaction(1000,accounts[2],{
	 		from: accounts[0]
	 	})}).then(function(){
	 		var a= contractInstance.list_of_transactions.length;
	 		console.log(contractInstance.list_of_transactions.length)
	 		assert.equal(a,0)
	 		console.log("Transaction added to the list of transactions");
	 	});
	})
	
		
	it("Signing a transaction", function(){
		return deployMultisig([accounts[0], accounts[1]],[0,3],2).then(function(instance){
	 	contractInstance= instance;
	 	return contractInstance.submitTransaction(1000,accounts[2],{
	 		from: accounts[1]
	 	})}).then(function(){
	 	contractInstance.sign(0,{
	 		from: accounts[0]
	 	});
	 	var ans=contractInstance.check_number_of_verifications(0,{
	 		from:accounts[0]
	 	});
	 	//Since there is only 1 signer required the contract should
	 	//pass and return 1. The contract will succesfully execute
	 	assert(ans,0)
	 }).then(function(){
	 	contractInstance.sign(0,{
	 		from: accounts[1]
	 	});
	 	var ans=contractInstance.check_number_of_verifications(0,{
	 		from:accounts[0]
	 	});
	 	//Since there is only 1 signer required the contract should
	 	//pass and return 1. The contract will succesfully execute
	 	assert(ans,1)
	 });
	 })
    //    Get initial balances of first and second account.
 	
    
 	

 	it("Completion of transaction with appropriate balance", function(){
		return deployMultisig([accounts[0], accounts[1]],[0,3],2).then(function(instance){
	 	contractInstance= instance;
	})
	.then(function(){
		contractInstance.sendTransaction({
			to: contractInstance.address,
			from:accounts[4],
			value: 10**18,
		})
	}).then(function(){
		var bal=contractInstance.Showbalance({
			from:accounts[0]
		});
		return bal;
	}).then(function(result){
		console.log("Balance of Wallet "+result);
	}).then(function(){
		var balanceAccount=web3.eth.getBalance(accounts[4]);
			return balanceAccount;
	}).then(function(result){
		console.log("Balance of account[4] initially"+ result);
		contractInstance.submitTransaction(40000000, accounts[4],{
			from:accounts[1]
		})
	}).then (function(){	
		contractInstance.sign(0,{
	 		from: accounts[1]
	 	});
	}).then(function(){
	 	 contractInstance.completeTransaction(
	 		0,{
	 		from: accounts[0]
	 	});
	 }).then(function(){
	 	var transaction =contractInstance.list_of_transactions(0); 
	 	return transaction;
	 }).then(function(result){
	 	 assert(result[2], true)
	 }).then(function(){
	 	var balanceAccount=web3.eth.getBalance(accounts[4]);
			return balanceAccount;
	 }).then(function(result){
	 	console.log("Balance of account[4] after transaction is: "+ result);
	 });
	})


	
	it("Adding new Users",function(){
		return deployMultisig([accounts[0], accounts[1]],[0,3],2).then(function(instance){
		 	contractInstance= instance;
		}).then(function(){
			return contractInstance.requestNewController(accounts[2],true,2,{
				from: accounts[0]
			});

		}).then(function(){
			return contractInstance.forRequest({
				from: accounts[1]
			});
		}).then(function(){
		return	contractInstance.proceedWithRequest	({
				from: accounts[0]	
			});	
		}).then(function(){
			return contractInstance.transactionControllers(accounts[2])
		}).then(function(result){
			console.log("Added User present status: "+ result);
		return	assert.equal(result,true)
		});
	})

	


	it("Deleting existing user",function(){
		return deployMultisig([accounts[0], accounts[1]],[0,3],2).then(function(instance){
		 	contractInstance= instance;
		})
		.then(function(){
			return contractInstance.requestNewController(accounts[0],false,2,{
				from: accounts[1]
			});
		}).then(function(){
		 return contractInstance.forRequest({
			from: accounts[0]
		});
		}).then(function(){
		return	contractInstance.proceedWithRequest	({
				from: accounts[1]	
			});	
		}).then(function(){
			return contractInstance.transactionControllers(accounts[0])
		}).then(function(result){
			console.log("Removed User present status: "+ result);
			return assert.equal(false,result)
		});
	})
 	

 	//Test should Return FALSE due to inapproriate wallet balance
 	it("Completion Of Transaction with 0 balance", function(){
	return deployMultisig([accounts[0], accounts[1]],[0,3],2).then(function(instance){
	 	contractInstance= instance;
	 	return contractInstance.submitTransaction(1000,accounts[2],{
	 		from: accounts[1]
	 	})}).then(function(){
	 	 contractInstance.sign(0,{
	 		from: accounts[1]
	 	});
	 	return contractInstance.list_of_transactions(0);
	 }).then(function(){
	 	 contractInstance.completeTransaction(
	 		0,{
	 		from: accounts[0]
	 	});
	 	return contractInstance.list_of_transactions(0);
	 }).then(function(result){
	 	console.log("The transaction should return false confirmation because 0 balance in wallet");
	 	console.log(result.confirmed);
	 	return assert.equal(result.confirmed,0)
	 });
	})

})
	