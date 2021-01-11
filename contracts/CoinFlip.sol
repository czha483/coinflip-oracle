pragma solidity >=0.4.22 <0.9.0;
// pragma abicoder v2;

import "./provableAPI.sol";

contract CoinFlip is usingProvable {
  address payable public owner;
  uint public balance;

  struct Bet {
    bytes32 queryId;
    address payable player;
    uint stake;
    uint payout;
    bool resolved;
  }

  mapping(bytes32 => Bet) betMap;

  event BetSubmitted(bytes32 indexed queryId, address indexed player);
  event BetResolved(bytes32 indexed queryId, address indexed player, uint stake, uint payout);

  constructor() public payable {
    owner = msg.sender;
    balance += msg.value;
  }

  modifier onlyOwner() {
    require(msg.sender == owner,"Only Owner");
    _;
  }

  function deposit() public payable onlyOwner {
    balance += msg.value;
  }

  function withdraw() public onlyOwner {
    if (balance > 0) {
      msg.sender.transfer(balance); // or address(this).balance
      balance = 0;
    }
  }

  function terminate() public onlyOwner {
    selfdestruct(owner);
  }

  function submitBet() public payable {
    uint stake = msg.value;
    require(stake > 0, "stake must be positive");
    //require(stake <= balance, "stake should be no more then contract balance");
    //
    uint256 QUERY_EXECUTION_DELAY = 0;
    uint256 NUM_RANDOM_BYTES_REQUESTED = 1; // 1 byte, for an integer from 0 to 255
    uint256 GAS_FOR_CALLBACK = 200000;
    bytes32 queryId = provable_newRandomDSQuery(
      QUERY_EXECUTION_DELAY, NUM_RANDOM_BYTES_REQUESTED, GAS_FOR_CALLBACK);
    //
    betMap[queryId] = Bet(queryId, msg.sender, stake, 0, false);
    // must use event as a way to return value to frontend.
    // frontend cannot get the function return value using send(),
    // can get using call() but it is for view only function.
    emit BetSubmitted(queryId, msg.sender);
  }

  function resolveBet(bytes32 _queryId, uint256 _oracleNumber) private {
    Bet storage bet = betMap[_queryId];
    balance += bet.stake;
    uint payout = 0;
    if (_oracleNumber % 2 > 0) {
      // player lost
    } else {
      // player won
      payout = bet.stake * 2;
      if (payout > balance) {
        payout = balance;
      }
      balance -= payout;
      bet.player.transfer(payout);
    }
    bet.payout = payout;
    bet.resolved = true;
    emit BetResolved(bet.queryId, bet.player, bet.stake, bet.payout);
  }

  function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
    require(msg.sender == provable_cbAddress());
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result)));
    resolveBet(_queryId, randomNumber);
  }

    // function getBet(bytes32 _queryId) public view returns(Bet) {
    //   return betMap[_queryId];
    // }

}
