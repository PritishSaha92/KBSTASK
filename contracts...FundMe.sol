// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

error NotOwner();

contract FundMe {

    mapping(address => uint256) public addressToAmountFunded;
    mapping(address => bool) public hasContributed;

    address[] public funders;
    address public contractOwner;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address public /* immutable */ i_contractOwner;
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18;
    
    constructor() {
        i_contractOwner = msg.sender;
    }

    function getCurrentEthUsdRate() internal pure returns (uint256) {
        return 1917.79 * 1e8; // Currently 1 ETH = $1,917.79 USD
    }

    function fund() public payable {
        uint256 ethAmount = (MINIMUM_USD * 1e18) / getCurrentEthUsdRate();
        require(msg.value >= ethAmount, "You need to spend more ETH!");
        require(!hasContributed[msg.sender], "You have already contributed.");

        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);

        hasContributed[msg.sender] = true;
    }
    
    modifier onlyOwner {
        if (msg.sender != i_contractOwner) revert NotOwner();
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        contractOwner = newOwner;
    }
    
    function withdraw() public onlyOwner {
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

}
