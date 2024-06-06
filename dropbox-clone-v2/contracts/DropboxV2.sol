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

    event FileDeleted(
        uint fileId,
        string fileHash,
        address payable uploader,
         uint deleteTime
    );

    function getFileCount() public view returns (uint) {
        return fileCount;
    }

    function listFiles() public view returns (File[] memory) {
        uint count = getFileCount();
        File[] memory allFiles;// = new File[](count);

        uint countNotDeleted = 0;
        for (uint i = 1; i <= count; i++) {
            if (bytes(files[i].fileHash).length != 0) {
                countNotDeleted++;
            }
        }

        // retorn a empty array
        if (countNotDeleted == 0) {
            return new File[](0);
        }

        allFiles = new File[](countNotDeleted);
        uint index = 0;
        for (uint i = 1; i <= count; i++) {
            if (bytes(files[i].fileHash).length != 0) {
                allFiles[index] = files[i];
                index++;
            }
            
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

        // Verify the signature
        address uploader = verifySignature(_fileHash, v, r, s);

        // validate incomming data
        require(bytes(_fileHash).length > 0);
        require(bytes(_fileType).length > 0);
        require(bytes(_fileDescription).length > 0);
        require(bytes(_fileName).length > 0);
        //require(msg.sender!=address(0));
        require(_fileSize>0);

        fileCount++;
        files[fileCount] = File(
            fileCount, 
             _fileHash,
             _fileSize,
             _fileType,
             _fileName,
             _fileDescription,
             block.timestamp,
             payable(uploader)
        );

        emit FileUploaded(fileCount, _fileHash, _fileSize, _fileType, _fileName, _fileDescription, block.timestamp, payable(uploader));
    }

    function deleteFile(
        uint fileId,
        uint8 v, 
        bytes32 r, 
        bytes32 s) public {

        require(files[fileId].fileId != 0, "File does not exist");

         // Verify the signature
        address uploader = verifySignature(files[fileId].fileHash, v, r, s); 
    
        // Verifica que el archivo fue cargado por el remitente
        require(files[fileId].uploader == payable(uploader), "Unauthorized");
        
        // Elimina el archivo del mapping
        delete files[fileId];

        emit FileDeleted(fileId, files[fileId].fileHash, payable(uploader), block.timestamp);
    }

    function verifySignature(string memory _fileHash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // Prefix the hash according to the Ethereum signed message prefix
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked(prefix, _fileHash));
        
        // Recover the signer address
        address signer = ecrecover(ethSignedMessageHash, v, r, s);
        require(signer != address(0), "Invalid signature");
        return signer;
    }
}