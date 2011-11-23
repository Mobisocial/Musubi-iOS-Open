/*
 * TicTacToe is the application's main class
 */
function TicTacToe(app) {
    this.board = ["  ","  ","  ","  ","  ","  ","  ","  ","  "];
    this.init(app);
    this.myToken = this.players[0].id == Musubi.user.id ? "X" : "O";
}
TicTacToe.prototype = new SocialKit.Multiplayer.TurnBasedMultiplayerGame;

// App initializations
TicTacToe.prototype.init = function(app) {    
    //this.renderBoard();
    this.onUpdate(function(state) {
        this.board = state.s;
        $("#board").html(this.renderBoard());
        $("#turn").html(this.isMyTurn() ? "It's your turn!" : "Waiting for other player.");
    });
    
    SocialKit.Multiplayer.TurnBasedMultiplayerGame.prototype.init.call(this, app);

    for (var key in this.players) {
        $("#players").append('<li>' + this.players[key].name + '</li>');
    }
};

// Returns a HTML rendering of the board 
TicTacToe.prototype.renderBoard = function() {
    // need this because "this" will be out of scope in the makeCell function
    var thisGame = this;

    var table = $('<table></table>');
    for (var i=0; i<3; i++) {
        var row = $('<tr></tr>');
        for (var i2=0; i2<3; i2++) {
            // wrapped inside a function to locally scope idx
            var makeCell = function(idx) {
                var cell = $('<td>&nbsp;' + thisGame.board[idx] + '</td>');
                cell.click(function() {
                    thisGame.placeToken(idx);
                });
                row.append(cell);
            };
            makeCell(i*3 + i2);        
        }
        table.append(row);
    }
    
    return table;
};

TicTacToe.prototype.placeToken = function(idx) {
    // only place token on empty spots
    if (this.board[idx] == "  ") {
        this.board[idx] = this.myToken;
    }
    
    this.takeTurn(this.makeState())
};

// Returns the state
TicTacToe.prototype.makeState = function() {
    return {s: this.board};
};

TicTacToe.prototype.feedView = function() {
    var dummy = $('<div></div>');
    dummy.append(this.renderBoard());
    return '<html><head><style>td { border:1px solid black; min-width:18px; }table { background-color:#FC6; padding:8px;}</style></head><body><div>' + dummy.html() + '</div></body></html>';
}


/*
 * App launch when Musubi is ready
 */
var game = null;
Musubi.ready(function() {
    game = new TicTacToe(Musubi.app);
});