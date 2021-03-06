pragma solidity ^0.4.25;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./UsdPrice.sol";

contract ICO is Ownable {
    
    using SafeMath for uint256;
    
    UsdPrice public fiat;
    ERC20 public ELYC;
    
    uint256 private tokenPrice;
    uint256 private tokensSold;
    
    constructor() public {
        fiat = UsdPrice(0x2CDe56E5c8235D6360CCbb0c57Ce248Ca9C80909); //CHANGE TO MAINNET ADDRESS!!!!
        ELYC = ERC20(0xe19ebf68660ee9a332933315e087bda5e7927d73); //UPDATE TOKEN ADDRESS
        tokenPrice = 8; //$0.08
        tokensSold = 0;
    }
    
    
    /**
     * EVENTS
     * */
    event PurchaseMade(address indexed by, uint256 tokensPurchased, uint256 tokenPricee);
    event WithdrawOfELYC(address recipient, uint256 tokensSent);
    event TokenPriceChanged(uint256 oldPrice, uint256 newPrice);
     
     

    /**
     * GETTERS
     * */  
     
    /**
     * @return The unit price of the ELYC token in ETH. 
     * */
    function getTokenPriceInETH() public view returns(uint256) {
        return fiat.USD(0).mul(tokenPrice);
    }
    
    
    /**
     * @return The unit price of ELYC in USD cents. 
     * */
    function getTokenPriceInUsdCents() public view returns(uint256) {
        return tokenPrice;
    }
    
    
    /**
     * @return The total amount of tokens which have been sold.
     * */
    function getTokensSold() public view returns(uint256) {
        return tokensSold;
    }
    
    
    /**
     * @return 1 ETH worth of ELYC tokens. 
     * */
    function getRate() public view returns(uint256) {
        uint256 e18 = 1e18;
        return e18.div(getTokenPriceInETH());
    }


    /**
     * Fallback function invokes the buyTokens() function when ETH is received to 
     * enable easy and automatic token distributions to investors.
     * */
    function() public payable {
        buyTokens(msg.sender);
    }
    
    
    /**
     * Allows investors to buy tokens. In most cases this function will be invoked 
     * internally by the fallback function, so no manual work is required from investors
     * (unless they want to purchase tokens for someone else).
     * @param _investor The address which will be receiving ELYC tokens 
     * @return true if the address is on the blacklist, false otherwise
     * */
    function buyTokens(address _investor) public payable returns(bool) {
        require(_investor != address(0) && msg.value > 0);
        ELYC.transfer(_investor, msg.value.mul(getRate()));
        tokensSold = tokensSold.add(msg.value.mul(getRate()));
        owner.transfer(msg.value);
        emit PurchaseMade(_investor, msg.value.mul(getRate()), getTokenPriceInETH());
        return true;
    }
    
    
    /**
     * ONLY OWNER FUNCTIONS
     * */
     
    /**
     * Allows the owner to withdraw any ERC20 token which may have been sent to this 
     * contract address by mistake. 
     * @param _addressOfToken The contract address of the ERC20 token
     * @param _recipient The receiver of the token. 
     * */
    function withdrawAnyERC20(address _addressOfToken, address _recipient) public onlyOwner {
        ERC20 token = ERC20(_addressOfToken);
        token.transfer(_recipient, token.balanceOf(address(this)));
    }
    

    /**
     * Allows the owner to withdraw any unsold ELYC tokens at any time during or 
     * after the ICO. Can also be used to process offchain payments such as from 
     * BTC, LTC or any other currency and can be used to pay partners and team 
     * members. 
     * @param _recipient The receiver of the token. 
     * @param _value The total amount of tokens to send 
     * */
    function withdrawELYC(address _recipient, uint256 _value) public onlyOwner {
        require(_recipient != address(0));
        ELYC.transfer(_recipient, _value);
        emit WithdrawOfELYC(_recipient, _value);
    }
    
    
    /**
     * Allows the owner to change the price of the token in USD cents anytime during 
     * the ICO. 
     * @param _newTokenPrice The price in cents. For example the value 1 would mean 
     * $0.01
     * */
    function changeTokenPriceInCent(uint256 _newTokenPrice) public onlyOwner {
        require(_newTokenPrice != tokenPrice && _newTokenPrice > 0);
        emit TokenPriceChanged(tokenPrice, _newTokenPrice);
        tokenPrice = _newTokenPrice;
    }
    
    
    /**
     * Allows the owner to kill the ICO contract. This function call is irreversible
     * and cannot be invoked until there are no remaining ELYC tokens stored on the 
     * ICO contract address. 
     * */
    function terminateICO() public onlyOwner {
        require(ELYC.balanceOf(address(this)) == 0);
        selfdestruct(owner);
    }
}


