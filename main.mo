import Array "mo:base/Array"; 
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import List "mo:base/List";

actor{

    private type Time = Time.Time;
    private type Message = {
        text: Text;
        time: Time;
    };
    private type MyBlog = actor{
        follow: shared (Principal) -> async ();
        follows: shared query() -> async [Principal];
        post: shared (Time) -> async ();
        posts: shared query (Time) -> async [Message];
        timeline: shared (Time) -> async [Message];
    };

    stable var followed : List.List<Principal> = List.nil();
    stable var messages : List.List<Message> = List.nil();

    public shared func follow(id: Principal) : async (){
        followed := List.push(id, followed);
    };
    
    public shared query func follows() : async [Principal]{
        List.toArray(followed)
    };

    public shared ({caller}) func post(text: Text) : async (){
        //Security Check
        //assert(Principal.toText(caller) == "..."); 
        var msg : Message = {
            text = text;
            time = Time.now();
        };
        messages := List.push(msg, messages);
    };

    public shared query func posts(since: Time) : async [Message]{
        var all : List.List<Message> = List.nil();
        for(msg in Iter.fromArray(List.toArray(messages))){
            if(msg.time >= since){
                all := List.push(msg, all);
            };
        };
        List.toArray(all)
    };

    public shared func timeline(since: Time) : async [Message]{
        var all : List.List<Message> = List.nil();
        for(id in Iter.fromList(followed)){
            let canister : MyBlog = actor(Principal.toText(id));
            let msgs = await canister.posts(since);
            for(msg in Iter.fromArray(msgs)){
                all := List.push(msg, all);
            };
        };
        List.toArray(all)
    };

    public type ChunkId = Nat;
    public type HeaderField = (Text, Text);
    public type StreamingStrategy = {
        #Callback : {
        token : StreamingCallbackToken;
        callback : shared query StreamingCallbackToken -> async StreamingCallbackHttpResponse;
        };
    };
    public type StreamingCallbackToken = {
        key : Text;
        sha256 : ?[Nat8];
        index : Nat;
        content_encoding : Text;
    };
    public type HttpRequest = {
        url : Text;
        method : Text;
        body : [Nat8];
        headers : [HeaderField];
    };
    public type HttpResponse = {
        body : Blob;
        headers : [HeaderField];
        streaming_strategy : ?StreamingStrategy;
        status_code : Nat16;
    };
    public type Key = Text;
    public type Path = Text;
    public type SetAssetContentArguments = {
        key : Key;
        sha256 : ?[Nat8];
        chunk_ids : [ChunkId];
        content_encoding : Text;
    };
    public type StreamingCallbackHttpResponse = {
        token : ?StreamingCallbackToken;
        body : [Nat8];
    };

    stable var currentValue : Nat = 0;

    // Increment the counter with the increment function.
    public func increment() : async () {
        currentValue += 1;
    };

    // Read the counter value with a get function.
    public query func get() : async Nat {
        currentValue
    };

    // Write an arbitrary value with a set function.
    public func set(n: Nat) : async () {
        currentValue := n;
    };

    public func greet(name : Text) : async Text {
        return "Hello, " # name # "!";
    };

    public shared query func http_request(request : HttpRequest) : async HttpResponse {
        {
            body = Text.encodeUtf8("<html><body>"#debug_show(currentValue)#"</body></html>");
            headers = [];
            streaming_strategy = null;
            status_code = 200;
        }
    };

    public shared({caller}) func qsort(arr : [Int]) : async [Int]{
        if(Iter.size<Int>(Array.vals<Int>(arr)) == 0){
            return [];
        };
        var re0_arr = Array.make<Int>(arr[0]);
        re0_arr := Array.append<Int>(re0_arr, arr);
        var tmp_arr : [var Int] = Array.thaw<Int>(re0_arr);
        sort(tmp_arr, 1, Iter.size<Int>(Array.vals<Int>(arr)));
        var ans_arr : [Int] = [];
        for(i in Iter.range(1, Iter.size<Int>(Array.vals<Int>(arr)))){
            ans_arr := Array.append<Int>(ans_arr, Array.make<Int>(tmp_arr[i]));
        };
        ans_arr
    };

    private func sort(s : [var Int], start : Nat, end : Nat) : (){    //初次为0, length - 1
        var i = start;
        var j = end;
        s[0] := s[start];
        while(i < j){
            while(i < j and s[0] < s[j]){
                j := j - 1;
            };
            if(i < j){
                s[i] := s[j];
                i := i + 1;
            };
            while(i < j and s[i] <= s[0]){
                i := i + 1;
            };
            if(i < j){
                s[j] := s[i];
                j := j - 1;
            };
        };
        s[i] := s[0];
        if(start < i){
            sort(s, start, j - 1);
        };
        if(i < end){
            sort(s, j + 1, end);
        };
    };
}
