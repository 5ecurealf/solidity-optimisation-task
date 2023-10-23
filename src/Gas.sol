// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./Ownable.sol";

contract GasContract is Ownable {
    // bool public constant tradeFlag = true;
    // bool public constant dividendFlag = true;

    uint256 public totalSupply; // cannot be updated
    uint256 public paymentCounter;
    mapping(address => uint256) public balances;
    // uint256 public tradePercent = 12;
    // address public contractOwner;
    // uint256 public tradeMode = 0;
    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;

    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }

    History[] public paymentHistory; // when a payment was updated

    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        bool adminUpdated;
        address recipient;
        address admin; // administrators address
        uint256 amount;
    }

    struct History {
        uint256 lastUpdate;
        address updatedBy;
        uint256 blockNumber;
    }
    bool wasLastOdd = true;
    mapping(address => bool) public isOddWhitelistUser;

    struct ImportantStruct {
        uint256 amount;
        bool paymentStatus;
        address sender;
    }
    mapping(address => ImportantStruct) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);

    modifier onlyAdminOrOwner() {
        // address senderOfTx = msg.sender;
        if (checkForAdmin(msg.sender)) {
            require(
                checkForAdmin(msg.sender),
                "Gas Contract Only Admin Check-  Caller not admin"
            );
            _;
        } else if (msg.sender == _owner) {
            _;
        } else {
            revert(" only admin or Onwer can execute");
        }
    }

    // modifier checkIfWhiteListed(address sender) {
    //     uint256 usersTier = whitelist[sender];
    //     require(
    //         (usersTier > 0 && usersTier < 4),
    //         "user's tier is incorrect, it cannot be over 4 as the only tier we have are: 1, 2, 3"
    //     );
    //     _;
    // }

    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(address admin, uint256 ID, uint256 amount);
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        // contractOwner = msg.sender;
        totalSupply = _totalSupply;

        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == _owner) {
                    balances[_owner] = totalSupply;
                    emit supplyChanged(_admins[ii], totalSupply);
                } else {
                    balances[_admins[ii]] = 0;
                    emit supplyChanged(_admins[ii], 0);
                }
            }
        }
    }

    function getPaymentHistory()
        public
        payable
        returns (History[] memory paymentHistory_)
    {
        return paymentHistory;
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        bool admin = false;
        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (administrators[ii] == _user) {
                admin = true;
            }
        }
        return admin;
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        uint256 balance = balances[_user];
        return balance;
    }

    // function getTradingMode() public view returns (bool mode_) {
    //     bool mode = false;
    //     if (tradeFlag == 1 || dividendFlag == 1) {
    //         mode = true;
    //     } else {
    //         mode = false;
    //     }
    //     return mode;
    // }

    // function addHistory(
    //     address _updateAddress,
    //     bool _tradeMode
    // ) public returns (bool status_, bool tradeMode_) {
    //     History memory history;
    //     history.blockNumber = block.number;
    //     history.lastUpdate = block.timestamp;
    //     history.updatedBy = _updateAddress;
    //     paymentHistory.push(history);
    //     bool[] memory status = new bool[](tradePercent);
    //     for (uint256 i = 0; i < tradePercent; i++) {
    //         status[i] = true;
    //     }
    //     return ((status[0] == true), _tradeMode);
    // }

    function getPayments(
        address _user
    ) public view returns (Payment[] memory payments_) {
        require(
            _user != address(0),
            "Gas Contract - getPayments function - User must have a valid non zero address"
        );
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

    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) public onlyAdminOrOwner {
        require(
            (_ID > 0 && _ID <= payments[_user].length),
            "ID must be greater than 0 and must exist"
        );
        require(_amount > 0, "Amount must be greater than 0");
        require(
            _user != address(0),
            "Admin must have a valid non zero address"
        );

        address senderOfTx = msg.sender;
        uint256 id = _ID - 1;

        Payment storage paymentToUpdate = payments[_user][id];
        paymentToUpdate.adminUpdated = true;
        paymentToUpdate.admin = _user;
        paymentToUpdate.paymentType = _type;
        paymentToUpdate.amount = _amount;
        // payments[_user][id].adminUpdated = true;
        // payments[_user][id].admin = _user;
        // payments[_user][id].paymentType = _type;
        // payments[_user][id].amount = _amount;

        // bool tradingMode = getTradingMode();
        // bool tradingMode = (tradeFlag || dividendFlag);
        // addHistory(_user, tradingMode);
        // History memory history;
        // history.blockNumber = block.number;
        // history.lastUpdate = block.timestamp;
        // history.updatedBy = _user;

        paymentHistory.push(
            History({
                blockNumber: block.number,
                lastUpdate: block.timestamp,
                updatedBy: _user
            })
        );

        emit PaymentUpdated(senderOfTx, _ID, _amount);
        // for (uint256 ii = 0; ii < payments[_user].length; ii++) {
        //     if (payments[_user][ii].paymentID == _ID) {
        //         payments[_user][ii].adminUpdated = true;
        //         payments[_user][ii].admin = _user;
        //         payments[_user][ii].paymentType = _type;
        //         payments[_user][ii].amount = _amount;
        //         bool tradingMode = getTradingMode();
        //         addHistory(_user, tradingMode);
        //         emit PaymentUpdated(
        //             senderOfTx,
        //             _ID,
        //             _amount,
        //             payments[_user][ii].recipientName
        //         );
        //     }
        // }
    }

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

        wasLastOdd = !wasLastOdd;
        isOddWhitelistUser[_userAddrs] = wasLastOdd;
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        // address senderOfTx = ;

        uint256 usersTier = whitelist[msg.sender];
        require(
            (usersTier > 0 && usersTier < 4),
            "user's tier is incorrect, it cannot be over 4 as the only tier we have are: 1, 2, 3"
        );

        require(_amount > 3, "amount to send have to be bigger than 3");

        _transferFunds(msg.sender, _recipient, _amount - whitelist[msg.sender]);

        whiteListStruct[msg.sender] = ImportantStruct(
            _amount,
            true,
            msg.sender
        );

        // balances[msg.sender] -= _amount;
        // balances[_recipient] += _amount;
        // balances[msg.sender] += whitelist[msg.sender];
        // balances[_recipient] -= whitelist[msg.sender];
        // balances[msg.sender] -= _amount - whitelist[msg.sender];
        // balances[_recipient] += _amount - whitelist[msg.sender];

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

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
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
