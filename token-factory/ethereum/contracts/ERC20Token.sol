// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Token is ERC20, Pausable, Ownable {
    bool private isMintable;
    bool private isBurnable;
    bool private isPausable;
    uint8 _decimals;

    modifier isTokenMintable() {
        require(
            isMintable == true,
            "Not Mintable: Token not allowed to mint more!"
        );
        _;
    }

    modifier isTokenBurnable() {
        require(isBurnable == true, "Not Burnable: Tokens are not burnable!");
        _;
    }

    modifier isTokenPausable() {
        require(isPausable == true, "Not Pausable: Token not Pausable!");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _supply,
        uint8 _tokDecimals,
        bool _isMintable,
        bool _isBurnable,
        bool _isPausable
    ) ERC20(_name, _symbol) {
        isMintable = _isMintable;
        isBurnable = _isBurnable;
        isPausable = _isPausable;

        _decimals = _tokDecimals;
        _mint(tx.origin, _supply * 10 ** decimals());
        transferOwnership(tx.origin);
    }

    function decimals() override public view returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) public onlyOwner isTokenMintable {
        _mint(to, amount);
    }

    function burn(
        uint256 amount
    ) public isTokenBurnable {
        _burn(_msgSender(), amount);
    }

    function burnFrom(
        address account,
        uint256 amount
    ) public virtual onlyOwner isTokenBurnable {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function pause() public onlyOwner isTokenPausable {
        _pause();
    }

    function unpause() public onlyOwner isTokenPausable {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
