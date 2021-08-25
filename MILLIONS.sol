pragma solidity ^0.5.16;

//Safe Math Library
library SafeMath {


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
 
//ERC Token Standard #20 Interface
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
 
 
//Contract function to receive approval and execute function in one call
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}



// change contract name to the Token name
contract MILLIONS is ERC20Interface {
    using SafeMath for uint;
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    // enter uniswap address
    address public liquiditypool = 0x05b1420Ce1a0CAc98F69AD960A7d81BABBA814F4;
    address public burn = address(0);
    uint public withdrawalfee = 50;
    uint public unstakingfee =50;
    address public admin;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    address[] public stakers;
	mapping(address => uint) public stakingBalance;
	mapping(address=> bool) public hasStaked;

	// event to broadcast to user
	event Staking(address indexed owner, uint value, bool hasStaked);
	event Unstaking(address indexed owner, uint value, bool hasStaked);


    constructor() public {
        symbol = "Ms";    //change symbol
        name = "MILLIONS";  // change name
        decimals = 0;   // change decimals
        _totalSupply = 500000000;    // change total supply
        // the person who deploys the contract will receive the total supply balance of the token
        balances[msg.sender] = _totalSupply;
        
        admin = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
   
    }
    
    modifier onlyAdmin() {
        require(admin ==msg.sender, 'callable by admin only');
        _;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
 
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    // add 7% fee to people who remove liquidity from the liquidity pool
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        approve(to,tokens);
        require(allowed[from][to]>= tokens, "insufficient approved amount");
        require(from!=address(0), "not a valid address");
        
        uint FeeAmount = withdrawalfee.mul(tokens);
        
            if(from == liquiditypool) {
            //subtract amount withdrawn from the liquidity pool
            require(balances[from]>=tokens, 'not enough to transfer');
        
            balances[from] =balances[from].sub(tokens-FeeAmount/100);
            // burn the withdrawal fee
            transfer(burn, FeeAmount/100);
            // approved amount will reduce
            allowed[from][to] = allowed[from][to].sub(tokens);
                        
            // send remaining amount to the recipient
            balances[to] = balances[to].add(tokens-FeeAmount/100);
        
            } else {
            
            balances[from] = balances[from].sub(tokens);
            allowed[from][to] = allowed[from][to].sub(tokens);
            
            balances[to] = balances[to].add(tokens);
            }
              
        emit Transfer(from, to, tokens);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
 
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
 
    function setLiquidityPool (address _liquiditypool) onlyAdmin public {
        liquiditypool = _liquiditypool;
    }


    function staking(uint256 _amount) public {
	    approve(address(this), _amount);
	    transferFrom(msg.sender, address(this), _amount);
		// add to the staking balance (sToken)
		stakingBalance[msg.sender] = stakingBalance[msg.sender].add(_amount);

		//add user to stakers array "only if" they haven't staked already
		if(!hasStaked[msg.sender]) {
			stakers.push(msg.sender);
		}

		//update staking status
		hasStaked[msg.sender] = true;
		
		emit Staking(msg.sender, _amount, hasStaked[msg.sender]);

	}

	//allow withdrawal of tokens
	//deduct 7% --> defined at the beginning of the contract
	function unStaking(uint256 _amount) public {
		require(hasStaked[msg.sender]=true, 'no staked amount');
		require(stakingBalance[msg.sender]> 0, "staking balance cannot be 0" );
		// reduce the staking balance (sToken) to lower amount
		stakingBalance[msg.sender]=stakingBalance[msg.sender].sub(_amount);
		
		
		// transfer token to the sender, minus the withdrawal fee
		uint unStakeFee = unstakingfee.mul(_amount);
		balances[msg.sender]= balances[msg.sender].add(_amount);
		transfer(liquiditypool, unStakeFee/100);


		//Update staking status
		if(stakingBalance[msg.sender] ==0) {
			hasStaked[msg.sender]=false;
		} else {
			hasStaked[msg.sender]=true;
		}

		emit Unstaking(msg.sender, _amount, hasStaked[msg.sender]);
	}

    function () external payable {
        revert();
    }
}

