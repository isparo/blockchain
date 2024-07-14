// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

/*
public: Accesible desde cualquier lugar.
private: Accesible solo dentro del contrato.
internal: Accesible dentro del contrato y contratos derivados.
external: Accesible solo desde fuera del contrato.
view: No modifica el estado del contrato.
pure: No lee ni modifica el estado del contrato.
payable: Puede recibir Ether.
 */

contract Dappazon {

    // es el dueño de la applicacion de tienda en linea
    address public owner;

    struct Item {
        uint256 id;
        string name;
        CategoryEnum category;
        string image;
        uint256 cost;
        uint256 rating;
        uint256 stock;
    }

    struct Order {
        uint256 time;
        Item item;
    }

    mapping(uint256 => Item) public items;
    mapping(address => mapping(uint256 => Order)) public orders;
    mapping(address => uint256) public orderCount;

   uint256[] public electronicGrouping;
   uint256[] public homeGrouping;

    enum CategoryEnum {electronic, home}

    // evento usado cuando se añade un articulo a la venta
    event List(string name, uint256 cost, uint256 quantity);

    // evento usado cuando se se compra un articulo
    event Buy(address buyer, uint256 orderId, uint256 itemId);

    // modificador que nos permite acceder solo a funciones cuando el
    // que llama al contrato es el owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // en el constructor seteamos el owner a la direccion que deploya el contrato
    constructor() {
        owner = msg.sender;
    }

    // añadir productos
    function list(
        uint256 _id,
        string memory _name,
        string memory _category,
        string memory _image,
        uint256 _cost,
        uint256 _rating,
        uint256 _stock
    ) public onlyOwner {

        require(keccak256(bytes(_category)) == keccak256(bytes("electronic")) ||
        keccak256(bytes(_category)) == keccak256(bytes("home")), "Invalid category");

        CategoryEnum _catego;
        if (keccak256(bytes(_category)) == keccak256(bytes("electronic"))) {
            _catego = CategoryEnum.electronic;
        } else if (keccak256(bytes(_category)) == keccak256(bytes("home"))){
            _catego = CategoryEnum.home;
        }

        Item memory item = Item(
            _id,
            _name,
            _catego,
            _image,
            _cost,
            _rating,
            _stock
        );

        // Add Item to mapping
        items[_id] = item;
        addToCategoryArray(_id, _catego);
         // Emit event
        emit List(_name, _cost, _stock);
    }

    // hacer pedido
    function buy(uint256 _itemId) public payable {
        Item memory item = items[_itemId];

        // Require item is in stock
        require(item.stock > 0);
        // the buyer require to have balance
        require(msg.sender.balance >= item.cost, "Insufficient balance to buy item");

         // Require enough ether to buy item
        require(msg.value > 0, "invalid value");
        require(msg.value == item.cost);

         // Create order
        Order memory order = Order(block.timestamp, item);

        // Add order for user
        orderCount[msg.sender]++; // <-- Order ID
        orders[msg.sender][orderCount[msg.sender]] = order;

        // Subtract stock
        items[_itemId].stock = item.stock - 1;

        // Emit event
        emit Buy(msg.sender, orderCount[msg.sender], item.id);
    }

    // hacer corte de caja (withdraw)
    function withdraw() public onlyOwner payable {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success);
    }

    // listar productos por categorias
    function getByCategory(string memory _category) external view returns (Item[] memory) {
        uint256[] memory ids;
        Item[] memory results;

        if (keccak256(bytes(_category)) == keccak256(bytes("electronic"))) {
           ids = electronicGrouping;
        } else if (keccak256(bytes(_category)) == keccak256(bytes("home"))){
            ids = homeGrouping;
        }

        results = new Item[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
                results[i] = items[ids[i]];
        }
        return results;
    }
    
    // buscar productos

    // update existecia
    function updateStock(uint256 _id, uint256 newStock) external onlyOwner {
        require(_id > 0, "invalid ID");
        Item storage item = items[_id];
        item.stock = newStock;
    }

    function getHomeGroupingLength() public view returns (uint256) {
        return homeGrouping.length;
    }

    function getElectronicGroupingLength() public view returns (uint256) {
        return electronicGrouping.length;
    }

    function addToCategoryArray(uint256 _id, CategoryEnum _category) private {
        if (_category == CategoryEnum.electronic) {
            electronicGrouping.push(_id);
        } else if (_category == CategoryEnum.home) {
            homeGrouping.push(_id);
        }
    }
}