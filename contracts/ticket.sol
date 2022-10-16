// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./InPersonTicketNFT.sol";

contract Ticket is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public ohm;
    IERC20 public usdt;
    IERC20 public usdc;
    IERC20 public frax;
    IERC20 public dai;
    mapping (string => uint) public usdTicketPrices;
    mapping (string => uint) public ohmTicketPrices;
    string[] public ticketTypes;
    address public gnosisMultiSigAddr;
    address public inPersonTicketNFTAddr;
    constructor(address multisig, address nftAddr, address ohmAddr, address usdtAddr, address usdcAddr, address fraxAddr, address daiAddr) {
        ohm = IERC20(ohmAddr);
        usdt = IERC20(usdtAddr);
        usdc = IERC20(usdcAddr);
        frax = IERC20(fraxAddr);
        dai = IERC20(daiAddr);
        gnosisMultiSigAddr = multisig;
        inPersonTicketNFTAddr = nftAddr;
    }

    // Modifier to check token allowance
    modifier checkAllowance(string memory tokenName, string memory ticketName, bool isStableCoin) {
        uint256 tokenPrice = _getTicketPrice(tokenName, ticketName, isStableCoin);
        IERC20 _token = _getTokenIERCbyName(tokenName);
        require(_token.allowance(msg.sender, address(this)) >= tokenPrice, "Error");
        _;
    }

    
    function setTicketPrice(string memory ticketName, bool isStableCoin, uint ticketPrice) public onlyOwner {
        if (isStableCoin == true){
            usdTicketPrices[ticketName] = ticketPrice;
        }
        ohmTicketPrices[ticketName] = ticketPrice;
    }

    function buyTicket(string memory tokenName, string memory ticketName, bool isStableCoin) public checkAllowance(tokenName, ticketName, isStableCoin) {
        uint256 tokenPrice = _getTicketPrice(tokenName, ticketName, isStableCoin);
        IERC20 token = _getTokenIERCbyName(tokenName);
        token.safeTransferFrom(msg.sender, address(this), tokenPrice);
        InPersonTicketNFT(inPersonTicketNFTAddr).mintNFT(msg.sender);
    }
    
    function withdrawToken() external onlyOwner {
        // multi-sig: Gnosis wallet address
        uint256 ohmBalance = ohm.balanceOf(address(this));
        uint256 usdtBalance = usdt.balanceOf(address(this));
        uint256 usdcBalance = usdc.balanceOf(address(this));
        uint256 fraxBalance = frax.balanceOf(address(this));
        uint256 daiBalance = dai.balanceOf(address(this));
        ohm.safeTransfer(gnosisMultiSigAddr, ohmBalance);
        usdt.safeTransfer(gnosisMultiSigAddr, usdtBalance);
        usdc.safeTransfer(gnosisMultiSigAddr, usdcBalance);
        frax.safeTransfer(gnosisMultiSigAddr, fraxBalance);
        dai.safeTransfer(gnosisMultiSigAddr, daiBalance);
    }

    function _getTokenIERCbyName(string memory tokenName) private view returns (IERC20){
        if(keccak256(abi.encodePacked("ohm")) == keccak256(abi.encodePacked(tokenName))) {
            return ohm;
        } else if(keccak256(abi.encodePacked("usdt")) == keccak256(abi.encodePacked(tokenName))){
            return usdt ;
        } else if(keccak256(abi.encodePacked("usdc")) == keccak256(abi.encodePacked(tokenName))){
            return usdc ;
        } else if(keccak256(abi.encodePacked("frax")) == keccak256(abi.encodePacked(tokenName))){
            return frax ;
        }
        } else if(keccak256(abi.encodePacked("dai")) == keccak256(abi.encodePacked(tokenName))){
            return dai ;
        }
        revert("Invalid tokenName, it should be one of ohm, usdt, usdc, frax, dai");
    }

    function _getTicketPrice(string memory tokenName, string memory ticketName, bool isStableCoin) private view returns (uint) {
        if (isStableCoin == true){
            return usdTicketPrices[ticketName] * _getTokenDecimals(tokenName);
        }
        return ohmTicketPrices[ticketName] * _getTokenDecimals(tokenName);
    }

    function _getTokenDecimals(string memory tokenName) private pure returns (uint) {
        if(keccak256(abi.encodePacked("ohm")) == keccak256(abi.encodePacked(tokenName))) {
            return 9;
        } else if(keccak256(abi.encodePacked("usdt")) == keccak256(abi.encodePacked(tokenName))){
            return 6 ;
        } else if(keccak256(abi.encodePacked("usdc")) == keccak256(abi.encodePacked(tokenName))){
            return 6 ;
        } else if(keccak256(abi.encodePacked("frax")) == keccak256(abi.encodePacked(tokenName))){
            return 18 ;
        }
        } else if(keccak256(abi.encodePacked("dai")) == keccak256(abi.encodePacked(tokenName))){
            return 18 ;
        }
        revert("token Address not found!");
    }
}