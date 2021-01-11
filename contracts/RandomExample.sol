pragma solidity >=0.4.22 <0.9.0;

import "./provableAPI.sol";

contract RandomExample is usingProvable {
  //
  uint256 public latestNumber;
  //
  event LogNewProvableQuery(string description);
  event generatedRandomNumber(uint256 randomNumber);

  constructor() public {
    update();
  }

  function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
    require(msg.sender == provable_cbAddress());
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 100;
    latestNumber = randomNumber;
    emit generatedRandomNumber(randomNumber);
  }

  function update() payable public {
    uint256 QUERY_EXECUTION_DELAY = 0;
    uint256 NUM_RANDOM_BYTES_REQUESTED = 1; // 1 byte, for an integer from 0 to 255
    uint256 GAS_FOR_CALLBACK = 200000;
    bytes32 queryId = provable_newRandomDSQuery(
      QUERY_EXECUTION_DELAY, NUM_RANDOM_BYTES_REQUESTED, GAS_FOR_CALLBACK);
    emit LogNewProvableQuery("Provable query sent, standing by for the answer...");
  }

  function testRandom() public returns(bytes32) {
    bytes32 queryId = bytes32(keccak256(abi.encodePacked(msg.sender)));
    __callback(queryId, "1", bytes("test"));
    return queryId;
  }

}
