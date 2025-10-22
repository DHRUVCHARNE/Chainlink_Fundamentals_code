//SPDX-License-Identifier:MIT
pragma solidity ^0.8.26;
import {AggregatorV3Interface}  from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";	
import {MyERC20} from "./MyERC20.sol";

contract TokenShop is Ownable {
    AggregatorV3Interface internal immutable i_priceFeed;
    MyERC20 public immutable i_token;
     
    uint public constant TOKEN_DECIMALS=18;
    uint public constant TOKEN_USD_PRICE = 2*10**TOKEN_DECIMALS; // 2 USD
    
    event BalanceWithdrawn();
    error TokenShop_ZeroETHSent();
    error TokenShop_CouldNotWithdraw();


    constructor(address tokenAddress) Ownable(msg.sender) {
        i_token = MyERC20(tokenAddress);
        i_priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    receive() external payable {
        if(msg.value == 0) {revert TokenShop_ZeroETHSent();}

        i_token.mint(msg.sender,amountToMint(msg.value));
    }

    function amountToMint(uint256 amountinETH) public view returns (uint256) {
        uint256 ethUSD = uint256(getChainlinkDataFeedLatestAnswer())*10**10;//ETH/USD with 8 decimals -> 18 decimals
        uint256 ethAmountInUSD = amountinETH * ethUSD/10**18;//ETH=18 decimals
        return (ethAmountInUSD*10**TOKEN_DECIMALS)/TOKEN_USD_PRICE; //TOKEN=18 decimals
    }

    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        (,int price,,,)=i_priceFeed.latestRoundData();
        return price;
    }

    function withdraw() external onlyOwner {
        (bool success,) = payable(owner()).call{value:address(this).balance}("");
        if(!success) {
            revert TokenShop_CouldNotWithdraw();
        }
        emit BalanceWithdrawn();
    }
    

}