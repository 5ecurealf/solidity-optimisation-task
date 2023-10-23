// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./Ownable.sol";

contract GasContract is Ownable {
    // Try to group the variables by size to take advantage of storage slots.
    // Starting with smaller types first, then move to larger types.

    // Grouping 256-bit types together
    uint256 private totalSupply; // cannot be updated
    uint256 private paymentCounter;

    // History[] public paymentHistory; // when a payment was updated
    address[5] public administrators;

    // Mappings1
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => ImportantStruct) public whiteListStruct;
    mapping(address => Payment[]) private payments;

    // Enums and Structs (their order doesn't affect slot efficiency but is kept for clarity)
    enum PaymentType {
        BasicPayment
    }

    struct Payment {
        uint256 paymentID;
        address recipient;
        address admin; // administrators address
        uint256 amount;
        bool adminUpdated;
        PaymentType paymentType;
    }

    // struct History {
    //     uint256 lastUpdate;
    //     address updatedBy;
    //     uint256 blockNumber;
    // }

    struct ImportantStruct {
        uint256 amount;
        bool paymentStatus;
    }

    modifier onlyAdminOrOwner() {
        if (msg.sender == _owner || checkForAdmin(msg.sender)) {
            _;
        } else {
            revert("Only admin or owner allowed.");
        }
    }

    event AddedToWhitelist(address userAddress, uint256 tier);
    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    // event PaymentUpdated(address admin, uint256 ID, uint256 amount);
    event WhiteListTransfer(address indexed);

    function addToWhitelist(
        address _userAddrs,
        uint256 _tier
    ) public onlyAdminOrOwner {
        require(_tier < 255, "Tier must be less than 255.");

        if (_tier > 3) {
            whitelist[_userAddrs] = 3;
        } else if (_tier > 1) {
            whitelist[_userAddrs] = 2;
        } else {
            whitelist[_userAddrs] = 1;
        }

        emit AddedToWhitelist(_userAddrs, _tier);
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        require(_admins.length > 0, "admins array empty");
        totalSupply = _totalSupply;
        balances[msg.sender] = totalSupply;
        emit supplyChanged(msg.sender, totalSupply);

        for (uint256 ii = 0; ii < administrators.length; ii++) {
            administrators[ii] = _admins[ii];
        }
    }

    // function getPaymentHistory() external view returns (History[] memory) {
    //     return paymentHistory;
    // }

    function checkForAdmin(address _user) public view returns (bool) {
        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (administrators[ii] == _user) {
                return true;
            }
        }
        return false;
    }

    function balanceOf(address _user) external view returns (uint256 balance_) {
        uint256 balance = balances[_user];
        return balance;
    }

    function getPayments(address _user) public view returns (Payment[] memory) {
        return payments[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public {
        _transferFunds(msg.sender, _recipient, _amount);

        emit Transfer(_recipient, _amount);

        payments[msg.sender].push(
            Payment({
                paymentType: PaymentType.BasicPayment,
                recipient: _recipient,
                amount: _amount,
                paymentID: ++paymentCounter,
                adminUpdated: false, // Assuming default values for these fields.
                admin: address(0) // You can adjust based on your contract's logic.
            })
        );
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        // address senderOfTx = ;

        uint256 usersTier = whitelist[msg.sender];
        require(
            (usersTier > 0 && usersTier < 4),
            "Invalid tier; only 1, 2, 3 allowed."
        );

        require(_amount > 3, "need to send amount > 3");

        _transferFunds(msg.sender, _recipient, _amount - whitelist[msg.sender]);

        whiteListStruct[msg.sender] = ImportantStruct(_amount, true);

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(
        address sender
    ) public view returns (bool, uint256) {
        return (
            whiteListStruct[sender].paymentStatus,
            whiteListStruct[sender].amount
        );
    }

    fallback() external payable {
        payable(msg.sender).transfer(msg.value);
    }

    // Internal function to handle balance updates.
    function _transferFunds(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal {
        require(balances[_sender] >= _amount, "Sender insufficient Balance");
        balances[_sender] -= _amount;
        balances[_recipient] += _amount;
    }
}
