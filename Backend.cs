using Godot;
using Archipelago.MultiClient.Net;
using Archipelago.MultiClient.Net.MessageLog.Messages;
using Archipelago.MultiClient.Net.Enums;
using Archipelago.MultiClient.Net.Helpers;
using Archipelago.MultiClient.Net.Models;
using System.Collections.Generic;
using Godot.Collections;

public partial class Backend : Node
{
    ArchipelagoSession Session = ArchipelagoSessionFactory.CreateSession("localhost");

    int Slot = -1;

    [Signal]
    public delegate void APChatTextEventHandler(string text);

    [Signal]
    public delegate void APHintEventHandler(Array<string[]> strings);

    public override async void _ExitTree()
    {
        if (Session.Socket.Connected)
            await Session.Socket.DisconnectAsync();
        Session.MessageLog.OnMessageReceived -= OnMessageReceived;
        Session.Items.ItemReceived -= OnItemRecived;
        EmitSignalTreeExited();
    }


    public string Connect(string ip)
    {
        if (string.IsNullOrWhiteSpace(ip))
            return string.Empty;
        if (!ip.StartsWith("ws://"))
            ip = "ws://" + ip;
        Session = ArchipelagoSessionFactory.CreateSession(ip);
        Session.MessageLog.OnMessageReceived += OnMessageReceived;
        Session.Items.ItemReceived += OnItemRecived;
        try
        {
            // Attempts to connect to the ip and get the room info hosted. Fails 
            // when you timeout or any other refusal happens.
            var task = Session.ConnectAsync();
            task.Wait();
        } catch
        {
            return "Connection failed. The server may not be up!";
        }
        return $"Connected to {ip}";
    }

    void OnMessageReceived(LogMessage message)
    {
        EmitSignalAPChatText(message.ToString());
    }

    void OnItemRecived(ReceivedItemsHelper helper)
    {
        var item = helper.DequeueItem();
        var name = Session.Players.GetPlayerName(Slot);
        EmitSignalAPChatText($"{item.Player.Name} sent {item.ItemName} to {name}");
    }

    public void LoginSlot(string slot)
    {
        var task = Session.LoginAsync("", slot, ItemsHandlingFlags.AllItems
        , tags: ["AP", "TextOnly"]);
        var res = task.Result;
        if (res is LoginSuccessful succ) {
            Slot = succ.Slot;
            Session.Hints.TrackHints(OnHintUpdate, true, Slot ,succ.Team);
        }
    }

    public void SendMSG(string msg)
    {
        Session.Say(msg);
    }

    public void Disconnect()
    {
        if (Session.Socket.Connected)
            Session.Socket.DisconnectAsync();
    }

    void OnHintUpdate(Hint[] hints)
    {
        List<string[]> labels = new(hints.Length);
        foreach (var hint in hints)
        {
            var recv_player = Session.Players.GetPlayerInfo(hint.ReceivingPlayer);
            var finding_player = Session.Players.GetPlayerInfo(hint.FindingPlayer);
            var item = Session.Items.GetItemName(hint.ItemId, finding_player.Game);
            var location = Session.Locations.GetLocationNameFromId(hint.LocationId, finding_player.Game);
            var entrance = string.IsNullOrWhiteSpace(hint.Entrance) ? "None" : hint.Entrance;
            var status = hint.Status.ToString();
            string[] label =
            [
                recv_player.Name,
                item,
                finding_player.Name,
                location,
                entrance,
                status
            ];
            labels.Add(label);
        }
        Array<string[]> strings = [.. labels.ToArray()];
        EmitSignalAPHint(strings);
    }
}
