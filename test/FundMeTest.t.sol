// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "script/DeployFundMe.s.sol";

contract FundMeTest is Test{
    FundMe fundMe;
    uint256 constant FUND_AMOUNT = 10e18;
    uint256 constant STARTING_BALANCE = 10 ether;

    address USER = makeAddr("user");

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306); 
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinUsdIsFive() view public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testIsOwner() view public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testIsVersionAccurate() view public {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundsUpdateFundedDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: FUND_AMOUNT}();
        uint256 amount = fundMe.getAddressToAmountFunded(USER);
        assertEq(amount, FUND_AMOUNT);
    }

    function testFundersArray() public {
        vm.prank(USER);
        fundMe.fund{value: FUND_AMOUNT}();
        assertEq(fundMe.getFunderAddress(0), USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: FUND_AMOUNT}();
        _;
    }

    function testFundWithOnlyOwner() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingfundMeBalance = address(fundMe).balance;
        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingfundMeBalance+startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawWithMultipleFunders() public funded {
        // Arrange
        uint160 NumberOfFunders = 10;
        uint160 startingIndex = 1;

        for (uint160 i=startingIndex; i<NumberOfFunders; i++) {
            hoax(address(i), FUND_AMOUNT);
            fundMe.fund{value: FUND_AMOUNT}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(startingOwnerBalance+startingFundMeBalance, fundMe.getOwner().balance);
    }

    function testWithdrawWithMultipleFundersCheaper() public funded {
        // Arrange
        uint160 NumberOfFunders = 10;
        uint160 startingIndex = 1;

        for (uint160 i=startingIndex; i<NumberOfFunders; i++) {
            hoax(address(i), FUND_AMOUNT);
            fundMe.fund{value: FUND_AMOUNT}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        // Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(startingOwnerBalance+startingFundMeBalance, fundMe.getOwner().balance);
    }
}