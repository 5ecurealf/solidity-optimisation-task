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

    // Mappings
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => ImportantStruct) public whiteListStruct;
    mapping(address => Payment[]) private payments;

    // Enums and Structs (their order doesn't affect slot efficiency but is kept for clarity)
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
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
        address sender;
    }

    modifier onlyAdminOrOwner() {
        if (msg.sender == _owner || checkForAdmin(msg.sender)) {
            _;
        } else {
            revert("Only admin or owner can execute");
        }
    }

    event AddedToWhitelist(address userAddress, uint256 tier);
    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    // event PaymentUpdated(address admin, uint256 ID, uint256 amount);
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        require(_admins.length > 0, "admins array empty");
        totalSupply = _totalSupply;
        balances[msg.sender] = totalSupply;
        emit supplyChanged(msg.sender, totalSupply);

        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
            }
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

    function balanceOf(address _user) public view returns (uint256 balance_) {
        uint256 balance = balances[_user];
        return balance;
    }

    function getPayments(
        address _user
    ) public view returns (Payment[] memory payments_) {
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

    // function updatePayment(
    //     address _user,
    //     uint256 _ID,
    //     uint256 _amount,
    //     PaymentType _type
    // ) public onlyAdminOrOwner {
    //     require(
    //         (_ID > 0 && _ID <= payments[_user].length),
    //         "ID must be greater than 0 and must exist"
    //     );
    //     require(_amount > 0, "Amount must be greater than 0");
    //     require(
    //         _user != address(0),
    //         "Admin must have a valid non zero address"
    //     );

    //     address senderOfTx = msg.sender;
    //     uint256 id = _ID - 1;

    //     Payment storage paymentToUpdate = payments[_user][id];
    //     paymentToUpdate.adminUpdated = true;
    //     paymentToUpdate.admin = _user;
    //     paymentToUpdate.paymentType = _type;
    //     paymentToUpdate.amount = _amount;

    //     paymentHistory.push(
    //         History({
    //             blockNumber: block.number,
    //             lastUpdate: block.timestamp,
    //             updatedBy: _user
    //         })
    //     );

    //     emit PaymentUpdated(senderOfTx, _ID, _amount);
    // }

    function addToWhitelist(
        address _userAddrs,
        uint256 _tier
    ) public onlyAdminOrOwner {
        require(_tier < 255, "tier level should not be greater than 255");

        if (_tier > 3) {
            whitelist[_userAddrs] = 3;
        } else if (_tier > 1) {
            whitelist[_userAddrs] = 2;
        } else {
            whitelist[_userAddrs] = 1;
        }

        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        // address senderOfTx = ;

        uint256 usersTier = whitelist[msg.sender];
        require(
            (usersTier > 0 && usersTier < 4),
            "user's tier is incorrect, only tier we have are: 1, 2, 3"
        );

        require(_amount > 3, "amount to send have to be bigger than 3");

        _transferFunds(msg.sender, _recipient, _amount - whitelist[msg.sender]);

        whiteListStruct[msg.sender] = ImportantStruct(
            _amount,
            true,
            msg.sender
        );

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
