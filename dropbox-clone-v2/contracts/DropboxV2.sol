// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DropboxV2 {
    string public name = 'DropboxV2';
    uint public fileCount = 0;
    mapping (uint => File) public files;

    constructor() {}

    struct File {
        uint fileId;
        string fileHash;
        uint fileSize;
        string fileType;
        string fileName;
        string fileDescription;
        uint uploadTime;
        address payable uploader;
    }

    event FileUploaded(
        uint fileId,
        string fileHash,
        uint fileSize,
        string fileType,
        string fileName,
        string fileDescription,
        uint uploadTime,
        address payable uploader
    );

    function getFileCount() public view returns (uint) {
        return fileCount;
    }

    function listFiles() public view returns (File[] memory) {
        uint count = getFileCount();
        File[] memory allFiles = new File[](count);

        for (uint i = 1; i <= count; i++) {
            allFiles[i - 1] = files[i];
        }

        return allFiles;
    }

    // function to upload file info, but in this case the uplaoder is obtained from the signature
     function uploadFile(
        string memory _fileHash, 
        uint _fileSize, 
        string memory _fileType, 
        string memory _fileName, 
        string memory _fileDescription,
        uint8 v, 
        bytes32 r, 
        bytes32 s) public {

        // obtiene la direccion de la firma
        bytes32 messageHash = keccak256(abi.encodePacked(_fileHash, _fileSize, _fileType, _fileName, _fileDescription));
        address uploader = ecrecover(messageHash, v, r, s);
        require(uploader != address(0), "Invalid signature");

        // validate incomming data
        require(bytes(_fileHash).length > 0);
        require(bytes(_fileType).length > 0);
        require(bytes(_fileDescription).length > 0);
        require(bytes(_fileName).length > 0);
        require(msg.sender!=address(0));
        require(_fileSize>0);

        fileCount++;
        files[fileCount] = File(fileCount, 
             _fileHash,
             _fileSize,
             _fileType,
             _fileName,
             _fileDescription,
             block.timestamp,
             payable(uploader)//payable(msg.sender)
        );

        emit FileUploaded(fileCount, _fileHash, _fileSize, _fileType, _fileName, _fileDescription, block.timestamp, payable(uploader));
    }


}