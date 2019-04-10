//This Smart Contract enables the users to set weights of 
// the wallet controllers. The tramnsactions are passed 
// according to the cumulative votes of the controllers 

pragma solidity ^0.5.0;

contract ModifiedMultisigwallet {
    
    uint MAX_SIGNERS=10;
    

    struct Transaction {
        address payable to;
        uint amount;
        mapping(address=> bool) verified;
        bool confirmed;
    }
    
    struct controller{
        address add;
        bool decide;
    }
    
    controller Controller;
    uint num_of_signersRequired;
    uint countRequestOfController;
    uint16 ControllerWeight;
    address[] public signers;
    Transaction[] public list_of_transactions;
    
    // Note that these mappings are required so as to reduce the time taken
    // to search for various parameters of Transactions and Controllers
    // Instead of searching one by one, a person can directly access these parameters. 
    mapping(address=>bool) public transactionControllers;
    mapping(address=>uint16) public weightOfControllers;
    mapping(address=>bool) public decisionForControllers;
    
     event Submitted(address indexed sender, address indexed receiver);
     event Completed(uint id);
     event Deposited(address indexed sender, uint value);
     event OwnerAdded(address indexed owner,bool val);
     event OwnerRemoved(address indexed owner,bool val);
     event ControllerRequestDeleted(address indexed owner);
     event ControllerRequestSubmitted(address indexed owner);
     
     

    // check for increase in number of wallet Controllers 
    modifier userLimitNotExceeded(uint num){
       require(num<=MAX_SIGNERS,"Maxium number of signers is 20");
        _;
    }
    
    //Checks whether a user can verify the Transaction.
    modifier istransactionController(address user){
        require (transactionControllers[user]==true,"Transactions can be verified only by signer");
        _;
    }
    
    //Checks for the validity of transaction
    modifier validTransaction(uint index){
        require (index>=0,"Invalid Transaction");
        require (index<list_of_transactions.length,"Invalid Transaction");
        _;
    }
    
    // Checks whether a transaction is signed by the required number of signers
     modifier isFullyVerified(uint index){
        require(check_number_of_verifications(index));
        _;
    }
    
      
    modifier isnottransactionController(address user){
        require (transactionControllers[user]==false, "User is already a signer");
        _;
    }
    
    modifier verifiedWeights(){
        require(VerifiedWeights(), "Incorrect Weights");
        _;
    }
    uint totalWeight;
    function VerifiedWeights() public  returns(bool){
         totalWeight=0;
         for(uint i=0; i<signers.length; i++){
            totalWeight=totalWeight+weightOfControllers[signers[i]];
        }
        if(totalWeight>=num_of_signersRequired)
            return true;
        else
            return false;
    }
    // Initially during the deployment of smart contract one has to declare the number
    // of wallet controllers(transactionControllers) and their addresses.
    // Note:one cannot have 0 wallet controllers
    //      one cannot set the number of controllers greater than the number of signers 
    constructor ( address[] memory initialSigners, uint16[] memory weights,uint n) userLimitNotExceeded(initialSigners.length) public {
        require(initialSigners.length==weights.length,"Number of required weights should be equal to the number of signers");
        require(n>0, "Number of verifications required cannot be less than 1");
        if(n==0)
            num_of_signersRequired=initialSigners.length;    
        else
            num_of_signersRequired=n;
        
        signers=initialSigners;
        for(uint i=0; i<initialSigners.length; i++){
            weightOfControllers[initialSigners[i]]=weights[i];
        }
        
        require(VerifiedWeights(), "Incorrect Weights");
        for(uint i=0; i<initialSigners.length; i++){
            transactionControllers[initialSigners[i]]=true;
        }
        
        Controller.add=address(0);
        for(uint i=0; i<initialSigners.length; i++){
            decisionForControllers[initialSigners[i]]=false;
        }
        countRequestOfController=0;
    }
    
    
    // To add the transaction to the list of transactions
    // This can only be done by a transaction Controller
    function submitTransaction(uint amount, address payable to)public istransactionController(msg.sender) {
        list_of_transactions.push(Transaction({
            to:to,
            amount:amount,
            confirmed: false
        }));
       emit Submitted(msg.sender, to);
    }
    
    //Wallet Controllers can verify the transaction by using this method
    function sign(uint transactionIndex)public istransactionController(msg.sender) validTransaction(transactionIndex){
        list_of_transactions[transactionIndex].verified[msg.sender]=true;
    }
    
    // Checked  whether the minimum number of required verification(num_of_signersRequired) have been done to the transaction
    function check_number_of_verifications(uint index) public view returns (bool){
       uint signedCount = 0;
        for(uint i=0;i<signers.length;i++){
            if(list_of_transactions[index].verified[signers[i]])
                signedCount=signedCount+weightOfControllers[signers[i]];        
        }
        return signedCount>=num_of_signersRequired;
    }
    
    
    // To finally execute the transaction verified by all the transaction Controllers
    // Only a signer can call this function and verify a transaction.
    function completeTransaction(uint index) isFullyVerified(index) istransactionController(msg.sender) public{
        require (address(this).balance >= list_of_transactions[index].amount);
        require (list_of_transactions[index].confirmed == false);
        list_of_transactions[index].confirmed=true;
        list_of_transactions[index].to.transfer(list_of_transactions[index].amount);
        emit Completed(index);
    }
    
    
    // A fall back function to receive ether
    function () external  payable {
        if(msg.value>0)
            emit Deposited(msg.sender,msg.value);
    }
    // Get the balance(amount of ether) present in wallet(contract) currently.  
    function Showbalance() public view returns(uint){
        return address(this).balance;
    }
    
    // Note that smart contract beyond this is similar to previous one 
    // The Number of Wallet Controllers can be changed only with the consensus of all the existing wallet controllers
    //-----------------------------------------------------------------------------------------------------\\
   //                                  TO ADD AND REMOVE CONTROLLERS FROM THE WALLET                        \\
    
    modifier controllerNotExists(){
        require(Controller.add==address(0),"A request to remove or add a controller is already pending. Kindly complete/remove it.");
        _;
    }
    
    // Request for addition or deletion of a Controller
    // Here value == 1 means new wallet Controller is requested
    //      value == 0 means existing wallet Controller has to be removed
    // Unless a request is completed or deleted one cannot ask for another request 
    function requestNewController(address User,bool value, uint16 controllerWeight) istransactionController(msg.sender) 
    controllerNotExists() public {
        if(value==true){
            require(transactionControllers[User]==false);
            ControllerWeight=controllerWeight;
        }  
        else{
            require(transactionControllers[User]==true);
        }
        decisionForControllers[msg.sender]=true;
        countRequestOfController++;
        Controller.add=User;
        Controller.decide=value;
        emit ControllerRequestSubmitted(User);
    }
    
    // Controller request that has been requested is accepted 
    function forRequest() istransactionController(msg.sender) public{
        require(Controller.add!=address(0),"No previous request to add or remove controller");    
        require(decisionForControllers[msg.sender]==false);
        decisionForControllers[msg.sender]=true;
        countRequestOfController++;
    }
    
    // Controller request that has been submitted is denied
    function againstRequest() istransactionController(msg.sender) public{
        require(Controller.add!=address(0),"No previous request to add or remove controller");
        require(decisionForControllers[msg.sender]==true);
        decisionForControllers[msg.sender]=false;
        countRequestOfController--;
    }
    
    // Based on type of request the Request is executed (A new user is either added)
    // (or an old user is removed)
    function proceedWithRequest() istransactionController(msg.sender) public{
        require(Controller.add!=address(0),"No previous request to add or remove controller");
        require(countRequestOfController==signers.length);
        if(Controller.decide){
                require(signers.length + 1 <= MAX_SIGNERS);
                signers.push(Controller.add);
                 emit OwnerAdded(Controller.add, true);
                 weightOfControllers[Controller.add]=ControllerWeight;
                transactionControllers[Controller.add]=true;
                Controller.add=address(0);
                for(uint i=0; i<signers.length; i++){
                    decisionForControllers[signers[i]]=false;
                }
               
        }
        else{
            require(totalWeight-weightOfControllers[Controller.add] >= num_of_signersRequired,"Number of signers should be greater than number of signers required");
            transactionControllers[Controller.add] = false;
            for (uint i=0; i<signers.length - 1; i++)
                if (signers[i] == Controller.add) {
                    signers[i] = signers[signers.length - 1];
                    break;
                }
            emit OwnerRemoved(Controller.add, false);
            Controller.add=address(0);
            signers.length -= 1;    
        }
        countRequestOfController=0;
    }
    
    // If all the controllers decide to remove the request this function
    // deletes the current request and thus allows wallet controllers to again 
    // perform controller requests
    function deleteRequestForController() istransactionController(msg.sender) public{
         require(Controller.add!=address(0));
         require(countRequestOfController==0);
         emit ControllerRequestDeleted(Controller.add);
         Controller.add=address(0);
    }
}
