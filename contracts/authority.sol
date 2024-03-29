// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;




interface Igovernance_set {
    function AccessControl(address caller, address target, bytes4 Fselector) external returns (bool accessed);
}





contract Authority {

    error TheAddressIsNotValidForRAddress(address newRAddress);
    error AccessOnlyForThePendig();
    error TheAddressIsNotValidForGC(address NewGCAddress);
    error RemainingTimeUntilTheConfirmationDeadline(uint48 reminingTime);


    event TheNextPresidentWasElected(address indexed newPresidentAdd);
    event TheNewPresidentWasConfirmed(address indexed presidentAdd, uint32 indexed nonce);
    event TheNextGCAddressWasElected(address indexed newGCAddress);
    event TheNewGCAddressWasConfirmed(address indexed GCAddress, uint32 indexed version);
    event TheStatusOfBanningAllActivitiesAndDone(bool indexed baned, bool indexed done);
    event TheNextRepublicAddressWasElected(address indexed newRepublicAddress);
    event TheNewRepublicAddressWasConfirmed(address indexed RepublicAddress, uint32 indexed version);
    event TheNextRepublicAddressWasCancelled(address indexed PRAddress);
    event TheNextPrimeMinisterWasElected(address indexed newPrimeMinister);
    event TheNewPrimeMinisterWasConfirmed(address indexed primeMinisterAdd, uint32 indexed nonce);

    
    

    address private _pendigRepublicAddress;
    address private _pendingGCAddress;
    address private _pendigPresident;
    address _pendingPrimeMinister;
    uint48 immutable TimeFirstElection;
    uint48 private _delayConfirmRepublicAddress;


    struct access {
        address roleAdd;
        bool baned;
        uint32 nonce;
    }

        
    access private _president;
    access private _primeMinister;
    access private _governance;
    access private _Republic;
    // access private _primeMinister;
    
    modifier onlyRepublic() {
        if (TimeFirstElection < block.timestamp) {
            require(msg.sender == getRepublicAddress(), "Access is not valid");

        } else require(msg.sender == getPresidentAdd() && !getPresidentBan(), "Access is not valid");

        _;
    }

    modifier onlyPresident() {
        require(msg.sender == getPresidentAdd() && !getPresidentBan(), "Access is not valid");

        _;
    }

    modifier AccessCheck(address caller) {
        require(!getPresidentBan() && Igovernance_set(_governance.roleAdd).AccessControl(caller, msg.sender, msg.sig), "Access is not valid");
        
        _;
    }

    constructor() {
        TimeFirstElection = uint48(block.timestamp + 4400 days);
        _president.roleAdd = msg.sender;
        _president.nonce++;
    }

    function setPendingRepublicAddress(address newRAddress) public onlyRepublic {
        if (newRAddress.code.length > 0) {
            if (_president.roleAdd == msg.sender) {
                _transferRepublicAddress(newRAddress);

            } else {
                _delayConfirmRepublicAddress = uint48(block.timestamp + 15 days);
                _pendigRepublicAddress = newRAddress;
                emit TheNextRepublicAddressWasElected(newRAddress);
            }

        } else revert TheAddressIsNotValidForRAddress(newRAddress);

    }

    function transferRepublicAddress(address RAddress) public onlyRepublic {
        if (_delayConfirmRepublicAddress < block.timestamp) {
            require(_delayConfirmRepublicAddress != 0,"The request is invalid");
            if (_pendigRepublicAddress == RAddress) {
                delete _delayConfirmRepublicAddress;
                delete _pendigRepublicAddress;
                _transferRepublicAddress(RAddress);

            } else revert TheAddressIsNotValidForRAddress(RAddress);

        } else revert RemainingTimeUntilTheConfirmationDeadline(_delayConfirmRepublicAddress - uint48(block.timestamp));
    }

    function cancelPendingRepublicAddress(address PRAdress) public onlyRepublic {
        if (_pendigRepublicAddress == PRAdress) {
                delete _delayConfirmRepublicAddress;
                delete _pendigRepublicAddress;
                emit  TheNextRepublicAddressWasCancelled(PRAdress);

        } else revert TheAddressIsNotValidForRAddress(PRAdress);
    }

    function getRepublicAddress() public view returns (address RG) {
            return _Republic.roleAdd;
        }

        function getAuthorityAddress() public view returns (address) {
            return  address(this);
        }

    function setPendigPresident(address newPresident) public onlyRepublic {
        _pendigPresident = newPresident;
        _setPresidentBaned(true);
        _setPrimeMinisterBaned(true);

        emit TheNextPresidentWasElected(newPresident);
    }

    function transferPresident() public {
        if (_pendigPresident == msg.sender) {
            delete _pendigPresident;
            _president.roleAdd = msg.sender;
            _president.nonce++;
            _setPresidentBaned(false);

            emit TheNewPresidentWasConfirmed(_president.roleAdd, _president.nonce);

        } else revert AccessOnlyForThePendig();
    }

    function getPresidentAdd() public view returns (address) {
        return _president.roleAdd;
    }

    function getPresidentBan() public view returns (bool) {
        return _president.baned;
    }

    function setPendingPrimeMinister(address newPM) public onlyPresident {
        _pendingPrimeMinister = newPM;

        emit TheNextPrimeMinisterWasElected(newPM);
    }

    function transferPrimeMinister() public {
        if (_pendingPrimeMinister == msg.sender) {
            delete _pendingPrimeMinister;
            _primeMinister.roleAdd = msg.sender;
            _primeMinister.nonce++;
            if (_primeMinister.baned){
                _setPrimeMinisterBaned(false);
            }
            emit TheNewPrimeMinisterWasConfirmed(_primeMinister.roleAdd, _primeMinister.nonce);

        } else revert AccessOnlyForThePendig();
    }

    function getPrimeMinisterAdd() public view returns (address) {
        return _primeMinister.roleAdd;
    }

    function getPrimeMinisterBan() public view returns (bool) {
        return _primeMinister.baned;
    }


    function setPendingGovernanceContractAddress(address newGCAddress) public onlyRepublic {
        if (newGCAddress.code.length > 0) {
            _pendingGCAddress = newGCAddress;
            emit TheNextGCAddressWasElected(newGCAddress);

        } else revert TheAddressIsNotValidForGC(newGCAddress);

    }

    function transferGovernanceContractAddress(address pendingGCAdd) public onlyPresident {
        if (_pendingGCAddress == pendingGCAdd) {
            delete _pendingGCAddress;
            _governance.roleAdd = pendingGCAdd;
            _governance.nonce++;
            emit TheNewGCAddressWasConfirmed(_governance.roleAdd, _governance.nonce);

        } else revert TheAddressIsNotValidForGC(pendingGCAdd);
    }

    function getGovernance() public view returns (address) {
        return _governance.roleAdd;
    }

    function getgovernanceVersion() public view returns (uint32) {
        return _governance.nonce;
    }

    function setPresidentBaned(bool baned) public onlyRepublic {
        _setPresidentBaned(baned);
        _setPrimeMinisterBaned(baned);
    }

    function setPrimeMinister(bool baned) public onlyPresident {
        _setPrimeMinisterBaned(baned);
    }



    function _transferRepublicAddress(address RAddress) private {
        _Republic.roleAdd = RAddress;
        _Republic.nonce++;
        emit TheNewRepublicAddressWasConfirmed(_Republic.roleAdd, _Republic.nonce);
    }

    function _setPresidentBaned(bool baned) private {
        _president.baned = baned;
    }

    function _setPrimeMinisterBaned(bool baned) private {
        _primeMinister.baned = baned;
    }


}