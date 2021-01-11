var web3 = new Web3(Web3.givenProvider);
// the CoinFlip contract instance in Ganache.
var contractIns;
var contractOwnerAddr;
var contractAddr = "0x97304C0F892cA7089eBBB1a419a2b34bC54BF867";
// player account
var playerAddr;

$(document).ready(function() {
    window.ethereum.enable().then(function (accounts) {
      console.log("MetaMask accounts:", accounts);

      playerAddr = accounts[0];
      contractIns = new web3.eth.Contract(abi, contractAddr, {from: playerAddr});
      console.log("CoinFlip contract instance:", contractIns);

      contractIns.methods.owner().call(function(error, result) {
        contractOwnerAddr = result;
        console.log("get contract owner:", contractOwnerAddr);
        $("#contract_owner").text(contractOwnerAddr);
      });

      fetchData();
    });

  	window.ethereum.on('accountsChanged', function () {
  		web3.eth.getAccounts(function (error, accounts) {
  			console.log('MetaMask accounts changed', accounts);
        playerAddr = accounts[0];
  		});
  	});

    $("#stake_input").val(0.01);

    $("#play_button").click(play);
    $("#get_data_button").click(fetchData);
});

function play () {
  var stake = $("#stake_input").val();
  //
  contractIns.methods.submitBet().send({value: toWei(stake)})

  .on("error", function (error) {
    console.log("play() on error", error);
  })

  .on("transactionHash", function (hash) {
    console.log("play() on transaction hash", hash);
  })

  .on("confirmation", function (confNumber, receipt, latestBlockHash) {
    console.log("play() on confirmation #", confNumber);
    if (confNumber > 12) {
      // e.g notify user
    }
  })

  .on("receipt", function (receipt) {
    console.log("play() on receipt:", receipt);
    // got the BetSubmitted event directly in receipt.
    let submittedBet = receipt.events.BetSubmitted.returnValues;
    console.log("play() on receipt BetSubmitted event:", submittedBet);
    // subscribe to the BetResolved event once
    // https://web3js.readthedocs.io/en/v1.3.1/web3-eth-contract.html#once
    contractIns.once('BetResolved', {
        filter: {
          queryId: submittedBet.queryId,
          player: submittedBet.player, // just my wallet address
        },
        fromBlock: 0
    }, function(error, event){
       console.log("Received BetResolved event:", event, error);
       let resolvedBet = event.returnValues;
       let payout = parseInt(resolvedBet.payout);
       let stake = parseInt(resolvedBet.stake);
       if (payout > 0) {
         alert('You have WON '+toEther(payout - stake, 4)+' ether!!')
       } else {
         alert('You have LOST.');
       }
       console.log("bet payout in ether:", toEther(payout));
       //
       fetchData();
    });

  })

  // it seems the promise function result is exactly same as the 'receipt'.
  // .then(function (result) {
  //   console.log("play() result:", result);
  //   fetchData();
  // })
  ;

}

function fetchData() {
  web3.eth.getBalance(playerAddr).then(function (balance) {
    $("#player_balance").text(toEther(balance, 4));
  });
  web3.eth.getBalance(contractAddr).then(function (balance) {
    $("#contract_balance").text(toEther(balance, 4));
  });
}

function toEther(wei, precision) {
  if (0 < precision && precision < 18) {
    let a = Math.round(wei / (10 ** (18 - precision)));
    return a / (10 ** precision);
  } else {
    return wei / (10 ** 18);
  }
}

function toWei(ether) {
  return Math.round(ether * (10 ** 18));
}
