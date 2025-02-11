// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; // No cambiar la versión de Solidity
import "hardhat/console.sol";
import "./ExampleExternalContract.sol";



contract Staker {
    // Variables de estado
    mapping(address => uint256) public balances; // Guarda cuánto ETH ha depositado cada dirección.
    uint256 public constant threshold = 1 ether; // Define el umbral mínimo para completar la acción.
    uint256 public deadline; // Guarda el tiempo límite para la recaudación de fondos.
    bool public executed; // Indica si el contrato ya fue ejecutado.
    address public owner; // Dirección del creador del contrato.
    ExampleExternalContract public exampleExternalContract; // Referencia al contrato externo.

    event Stake(address indexed staker, uint256 amount); // Evento para registrar depósitos de ETH.

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
        deadline = block.timestamp + 7 days; // Cambiado de 30 segundos a 7 días
        owner = msg.sender; // Guarda la dirección del creador del contrato.
    }

    // Función para depositar ETH en el contrato
    function stake() external payable {
        require(block.timestamp < deadline, "Staking period over");
        require(msg.value > 0, "Must send ETH to stake"); 
        
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // Función para retirar fondos si el umbral no se alcanza
    function withdraw() external {
        require(block.timestamp >= deadline, "Staking period not over");
        require(address(this).balance < threshold, "Threshold met, no withdrawals");
        
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No funds to withdraw");
        
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // Función para ejecutar la acción si el umbral se alcanza
    function execute() external {
        require(block.timestamp >= deadline, "Deadline not reached");
        require(address(this).balance >= threshold, "Threshold not met");
        require(!executed, "Already executed");
        
        executed = true;
        exampleExternalContract.complete{value: address(this).balance}();
    }

    // Función para consultar el balance del contrato
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Función para consultar el tiempo restante antes del deadline
    function timeLeft() external view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    // Función especial para recibir ETH y automáticamente registrar el stake
    receive() external payable {
        require(block.timestamp < deadline, "Staking period over");
        require(msg.value > 0, "Must send ETH to stake");

        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }
}


