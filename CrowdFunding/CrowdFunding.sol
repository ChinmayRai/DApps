	pragma solidity ^0.4.23;

	interface token {
		function transfer(address receiver, uint amount) external;
	}

	contract CrowdFunding {
	    

		address public owner; // contract owner
		uint public deadline; // deadline for this contract to be closed
		bool public goalReached; // "Funding", "Campaign Success", "Campaign Failed"
		bool public end; // the end of funding
		uint public goalAmount; // target amount
		uint public totalAmount; //total amount
		uint public price;
		token public tokenReward;
		mapping(address => uint256) public investment;

		event GoalReached(address ownerAddress, uint amountRaisedValue);
		event FundTransfer(address backer, uint amount, bool isContribution);
	    
	    // Create modifier to limit to owner
	    modifier onlyOwner()    {
	        require(msg.sender==owner);
	        _;
	    }

	    // Create modifier to check if deadline has passed
	    modifier afterDeadline() {
			require (now >= deadline);
			_;
		}
		
		constructor(uint _durationMinutes, uint _goalAmount,uint _costOfToken, address _tokenAddress) public {
			// Initialize owner, deadline, goalAmount, goalReached,end, numbInvestors, totalAmount
			owner = msg.sender;
			deadline = now + _durationMinutes * 1 minutes;
			goalAmount = _goalAmount * 1 ether;
			price = _costOfToken * 1 ether;
			tokenReward = token(_tokenAddress);
			goalReached=false;
			end= false;
			totalAmount =0;
		}

		// Function to be called when investing
		function fund() public payable {
			// 1. Check if this crowd funding ended or not
			require(  now < deadline   );
			
			// 2. Set invest-related info and process funding
			investment[msg.sender] += msg.value;
			totalAmount += msg.value;
			tokenReward.transfer(msg.sender, msg.value / price);
			
			emit FundTransfer(msg.sender,msg.value, true);
		}


		function checkGoalReached () public onlyOwner {
		    
			// 1. Check if this crowd funding ended or not
			require(end==false);
			
			// 2. Check if the deadline is past or not
			require(now >= deadline);
			
			// 3-1. Check If this crowdfunding is successful
			if(totalAmount >= goalAmount ){	    goalReached=true;	emit GoalReached(owner, totalAmount);		}
			
			// Consider updating end
			end=true;
		}


		function withdraw() external afterDeadline{
			if(!goalReached){
				uint amount = investment[msg.sender];
				investment[msg.sender] = 0;
				if (amount > 0) {
					if (msg.sender.send(amount)) {  emit FundTransfer(msg.sender, amount, false); totalAmount -= amount;	}

					else {		investment[msg.sender] = amount;		}
				}
			}

			if( goalReached && owner==msg.sender){

				if (owner.send(totalAmount)) {  emit FundTransfer(owner, totalAmount, false); totalAmount = 0 ; 	} 
			}
		}

		// 1. Create function to destroy this contract
		function self_destroy () public onlyOwner {
		    selfdestruct(owner);
		}

	}


