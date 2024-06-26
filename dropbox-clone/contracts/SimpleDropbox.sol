// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleDropbox {
    string public name = 'SimpleDropbox';
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

    function uploadFile(
        string memory _fileHash, 
        uint _fileSize, 
        string memory _fileType, 
        string memory _fileName, 
        string memory _fileDescription) public {

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
             payable(msg.sender)
        );

        emit FileUploaded(fileCount, _fileHash, _fileSize, _fileType, _fileName, _fileDescription, block.timestamp, payable(msg.sender));
    }

    function listFiles() public view returns (File[] memory) {
        uint count = getFileCount();
        File[] memory allFiles = new File[](count);

        for (uint i = 1; i <= count; i++) {
            allFiles[i - 1] = files[i];
        }

        return allFiles;
    }
    
}
