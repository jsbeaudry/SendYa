// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./prices.sol";


contract MyContract is AccessControl, Pausable{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    using Math for uint256;

    address public tokenAddress;
    address public feeCollector;

    IERC20 public usdc;

    PriceStables public priceStables;
    mapping(string => address) public addresses;
    mapping(string => address) public phoneNumbers;


    event TokensReceived(address from, uint256 amount);

    constructor( address _priceStables, address usdc_) {
    
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);

        priceStables = PriceStables(_priceStables);

        usdc = IERC20(usdc_);
        feeCollector =  msg.sender;
    }

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), "Must have manager role");
        _;
    }

    modifier onlyOwner() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Must have ADMIN_ROLE role");
        _;
    }

    function grantNewRole(bytes32 role, address account) public onlyOwner {
        // Only the address with the "ADMIN_ROLE" can grant the "MANAGER_ROLE"
        _grantRole(role, account);
    }

    function revoveRole(bytes32 role, address account) public onlyOwner {
        // Only the address with the "ADMIN_ROLE" can grant the "MANAGER_ROLE"
        _revokeRole(role, account);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function changePriceFeed(address _priceAddr) public onlyOwner returns (bool) {
        require(
            _priceAddr != address(0),
            "price Stables address can't be null"
        );
        priceStables = PriceStables(_priceAddr);
        return true;
    }

    function addPhone(string memory encryptedPhoneNumber) public {
        phoneNumbers[encryptedPhoneNumber] = msg.sender;
    }

    function balance(string memory toCurrency) view public returns(uint256){
       
        int256 toCurrencyPrice = priceStables.stablesPrice(toCurrency);
        uint256 usdBalance = usdc.balanceOf(msg.sender);
        
        require( toCurrencyPrice>0, "Prices should sup to zero");

 
        if(addresses[toCurrency] == address(usdc)){
         
            return  usdBalance;
        }else {
            return (usdBalance  * uint256(toCurrencyPrice))/ 1e6;
           
        }
    }

    function balanceOf(address wallet, string memory toCurrency) view public returns(uint256){
       
        int256 toCurrencyPrice = priceStables.stablesPrice(toCurrency);
        uint256 usdBalance = usdc.balanceOf(wallet);
        
        require( toCurrencyPrice>0, "Prices should sup to zero");

        if(addresses[toCurrency] == address(usdc)){
            return  usdBalance;
        }else {
            return (usdBalance  * uint256(toCurrencyPrice))/ 1e6;
        }
    }

    function convert( string memory fromCurrency, string memory toCurrency, int256 amount) view  public returns(int256){
        
        int256 fromCurrencyPrice = priceStables.stablesPrice(fromCurrency);
        int256 toCurrencyPrice = priceStables.stablesPrice(toCurrency);

        int256 output = 0;

        if(addresses[fromCurrency] == address(usdc) && addresses[toCurrency] != address(usdc)){

            output = (amount * toCurrencyPrice) / 1e6;

        }if(addresses[fromCurrency] != address(usdc) && addresses[toCurrency] == address(usdc)){

            output = (amount * 1e6) / toCurrencyPrice;

        }else {
            int256 amount_ = (amount * 1e6) / fromCurrencyPrice;

            output = (amount_ * toCurrencyPrice) / 1e6;
        }

        return  output;
    }

    function transfert( string memory toCurrency, uint256 amount, address recipient, string memory phone, bool isPhone) public  {
       
        int256 toCurrencyPrice = priceStables.stablesPrice(toCurrency);
        
        require( toCurrencyPrice>0, "Prices should sup to zero");
        require( amount>0, "amount should sup to zero");


        if(isPhone && recipient == address(0)){
            recipient = phoneNumbers[phone];
        }

        require( recipient != address(0), "amount should sup to zero");
       
        uint256 amountToSend = 0;
        if(addresses[toCurrency] == address(usdc)){
            require(usdc.transferFrom(msg.sender, address(this), amount), "Transfer failed");
            uint256 amountFee = (amount * 1200) / (100 *1e3);
            amountToSend = amount - amountFee;
            usdc.transfer(recipient, amountToSend);
            usdc.transfer(feeCollector, amountFee);
        }else {
            uint256 amount_ = (amount * 1e6) / uint256(toCurrencyPrice);
            amount = amount_;
            require(usdc.transferFrom(msg.sender, address(this), amount), "Transfer failed");

            uint256 amountFee = (amount_ * 1200) / (100 *1e3);
             amountToSend = amount_ - amountFee;

            usdc.transfer(recipient, amountToSend);
            usdc.transfer(feeCollector, amountFee);
        }

        emit TokensReceived(msg.sender, amountToSend);
    }

    
    
}