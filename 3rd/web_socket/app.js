
function base64_decode(str){
    var c1, c2, c3, c4;
    var base64DecodeChars = new Array(
            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
            -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63, 52, 53, 54, 55, 56, 57,
            58, 59, 60, 61, -1, -1, -1, -1, -1, -1, -1, 0,  1,  2,  3,  4,  5,  6,
            7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
            25, -1, -1, -1, -1, -1, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36,
            37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1,
            -1, -1
            );
    var i=0, len = str.length, string = '';

    while (i < len){
        do{
            c1 = base64DecodeChars[str.charCodeAt(i++) & 0xff]
        } while (
                i < len && c1 == -1
                );

        if (c1 == -1) break;

        do{
            c2 = base64DecodeChars[str.charCodeAt(i++) & 0xff]
        } while (
                i < len && c2 == -1
                );

        if (c2 == -1) break;

        string += String.fromCharCode((c1 << 2) | ((c2 & 0x30) >> 4));

        do{
            c3 = str.charCodeAt(i++) & 0xff;
            if (c3 == 61)
                return string;

            c3 = base64DecodeChars[c3]
        } while (
                i < len && c3 == -1
                );

        if (c3 == -1) break;

        string += String.fromCharCode(((c2 & 0XF) << 4) | ((c3 & 0x3C) >> 2));

        do{
            c4 = str.charCodeAt(i++) & 0xff;
            if (c4 == 61) return string;
            c4 = base64DecodeChars[c4]
        } while (
                i < len && c4 == -1
                );

        if (c4 == -1) break;

        string += String.fromCharCode(((c3 & 0x03) << 6) | c4)
    }
    return string;
}


var cmds = [];
var client_cmds = [];
var client_cmds_hash = [];

function handle_base64(cmd)
{
    str = base64_decode(cmd.base64);
    var pos = 0;

    function to8(str)
    {
        var value = "00000000";
        return value.substring(0, value.length - str.length) + str;
    }


    function cmdInt(size)
    {

        size = size || 4;
        var value = "";
        for(var i=pos;i < pos + size;i++){
            value += to8(str.charCodeAt(i).toString(2));
        }
        //console.log(size + " " + value);
        pos += size;
        return parseInt(value, 2);
    }

    function cmdString()
    {
        var size = cmdInt(2);
        var result = str.substring(pos, pos + size);
        pos += size;
        return result;
    }

    function cmdPack()
    {
        var size = cmdInt();
        var data = str.substring(pos, pos + size);

        pos += size;
        return msgpack.unpack(data);
    }

    /*
    var result = [];
    for(var i=0;i < str.length;i++){
        result.push(to8(str.charCodeAt(i).toString(2)));
    }
    console.log(result);
    */
    
    function getCmdProtocol(cmd)
    {
        for(k in client_cmds)
        {
            if(client_cmds[k].cmd == cmd)
            {
                return client_cmds[k];
            }
        }
    }


    var proto = getCmdProtocol(getCmdsFromHash(cmd.Cmd));
    var result = {};
    for(k in proto)
    {
        if(k == "cmd")
        {
            result["_CMD_"] = proto[k];
            continue;
        }else if(proto[k] == "int"){
            result[k] = cmdInt();
        }else if(proto[k] == "string"){
            result[k] = cmdString();
        }else if(proto[k] == "pack"){
            result[k] = cmdPack();
        }
    }
    console.log(result);
    add("Recv: " + JSON.stringify(result));


    /*
    var result = [];
    for(var i=0;i < str.length;i++){
        result.push(to8(str.charCodeAt(i).toString(2)));
    }
    //console.log(result);

    var value = []
    for(var i=0; i < 4; ++i)
    {
        value += result[i]
    }
    console.log(parseInt(value, 2));
    console.log(parseInt(str.substr(1,4), 16));
    */
}

function saveCmdHash(data)
{
    for(k in data.Strs)
    {
        client_cmds_hash[data.Cmds[k]] = data.Strs[k];
    }
    //console.log(client_cmds_hash);
}

function getCmdsFromHash(hash)
{
    return client_cmds_hash[hash];
}


// Hx@2015-11-26 : update cmds view
function updateCmdView(cmds)
{
    $('#mycmd').children('div').remove();

    for ( var i=0 ; i < cmds.length ; ++i ) 
    {
        var obj = cmds[i]
            var divname = 'cmd_' + obj['cmd'];
        var str = '<div id="' + divname + '">';
        var cmd = "send_cmd(" + "'" + divname + "'" + ")";
        str = str + '<button type="button" onclick="' + cmd + '" >' + obj['cmd'] + '</button>';
        for (var p in obj)
        {
            if (p != 'cmd') {
                //if (typeof(obj[p]) != "number") {
                if (obj[p] != "int") {
                    str = str + p + ':<input type="text" name = "s_' + p + '" value="' + obj[p] + '"></input>';
                } else {
                    str = str + p + ':<input type="text" name = "i_' + p + '" value="' + obj[p] + '"></input>';
                }
            }
        }
        str = str + '</div>';
        $('#mycmd').append(str);
    }
}

// Hx@2015-11-26 : decode protocol.lua
function decodeProtocolStr(str)
{
    var protocol = {}

    var data = str.split("=");
    if (data.length != 2)
    {
        return;
    }
    protocol.cmd = data[0].replace(/\W*(\w+)\W*/, "$1");
    //protocol.arg = {};
    
    var params = data[1].replace(/\W*"(.*)"\W*/, "$1").split(",");
    for(k in params)
    {
        var val = params[k].replace(/\W*(.*)\W*/, "$1").split(" ");
        if(val.length != 2)
        {
            continue;
        }
        var type = val[0].replace(/\W*(\w+)\W*/,"$1");
        var name = val[1].replace(/\W*(\w+)\W*/,"$1");  
        protocol[name] = type;
        //protocol.arg[name] = type;
    }
    //console.log(protocol);
    return protocol;
}

function decodeProtocolFileStr(filestr)
{
    filestr = filestr.replace(/--.*/g,"")
    var reg_server_block = /[\s\S]*Server\s*=\s*{([^}]*)}[\s\S]*/;
    var server_block = filestr.replace(reg_server_block, "$1").split("\n");
    console.log(server_block);
    /*
    for(k in server_block)
    {
        decodeProtocolStr(server_block[k]);
    }
    */
    
    var reg_client_block = /[\s\S]*Client\s*=\s*{([^}]*)}[\s\S]*/;
    var client_block = filestr.replace(reg_client_block, "$1").split("\n");
    //console.log(client_block);

    function fillCmds(block)
    {
        var cmds = [];
        for(k in block)
        {
            var cmd = decodeProtocolStr(block[k]);
            if(cmd)
            {
                cmds.push(cmd);
            }
        }
        return cmds;
    }

    // upvalue
    cmds = fillCmds(server_block);
    client_cmds = fillCmds(client_block);
    
    updateCmdView(cmds);
    
    function reqHash()
    {
        if(websocket.readyState == websocket.OPEN)
        {
            var msg = {};
            msg._CMD_ = "hashStr";
            msg.strs = []
            for (k in client_cmds)
            {
                msg.strs.push(client_cmds[k].cmd);
            }
            msg.strs = JSON.stringify(msg.strs);
            //console.log(JSON.stringify(msg));
            websocket.send(JSON.stringify(msg))
        }
        
    }

    reqHash();
}

function  handleFiles(files)  
{
    if(files.length)  
    {  
        var file = files[0];  
        var reader = new FileReader();  
        reader.onload = function()  
        {  
            decodeProtocolFileStr(this.result);
            //var filestr = this.result;  

            //console.log(filestr);
        };  
        reader.readAsText(file);  
    }  
}  
