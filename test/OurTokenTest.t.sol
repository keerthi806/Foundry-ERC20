// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    uint256 public constant STARTING_BALANCE = 100 ether;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    address charlie = makeAddr("charlie");

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    // Test 1: Check Bob's initial balance after the transfer
    function testInitialBalance() public view {
        assertEq(STARTING_BALANCE, ourToken.balanceOf(bob));
    }

    // Test 2: Test that allowances work correctly
    function testAllowanceWorks() public {
        uint256 initialAllowance = 1000;

        // Bob allows Alice to spend tokens on his behalf
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 500;

        // Alice transfers from Bob's account to herself
        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
        assertEq(ourToken.allowance(bob, alice), initialAllowance - transferAmount);
    }

    // Test 3: Allowance should prevent over-spending
    function testAllowanceLimit() public {
        uint256 initialAllowance = 1000;

        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 overLimitTransfer = 1500;

        // Attempting to transfer more than allowed should revert
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(bob, alice, overLimitTransfer);
    }

    // Test 4: Transfers without allowance should fail
    function testTransferWithoutApproval() public {
        uint256 transferAmount = 500;

        // Alice tries to transfer from Bob without allowance, should fail
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(bob, alice, transferAmount);
    }

    // Test 5: Bob can't transfer more than his balance
    function testTransferMoreThanBalance() public {
        uint256 transferAmount = STARTING_BALANCE + 1 ether;

        vm.prank(bob);
        vm.expectRevert();
        ourToken.transfer(alice, transferAmount);
    }

    // Test 6: Ensure that transfer of 0 tokens works
    function testTransferZeroTokens() public {
        vm.prank(bob);
        ourToken.transfer(alice, 0);

        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE);
        assertEq(ourToken.balanceOf(alice), 0);
    }

    // Test 7: Ensure proper revert when transferring to the zero address
    function testTransferToZeroAddress() public {
        uint256 transferAmount = 10 ether;

        vm.prank(bob);
        vm.expectRevert();
        ourToken.transfer(address(0), transferAmount);
    }

    // Test 8: Revert when trying to approve to the zero address
    function testApproveToZeroAddress() public {
        uint256 approveAmount = 10 ether;

        vm.prank(bob);
        vm.expectRevert();
        ourToken.approve(address(0), approveAmount);
    }
}
