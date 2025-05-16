using Godot;
using System;

public partial class LoginMenu : Control
{
	public override void _Ready()
	{
		var buttons = GetNode<VBoxContainer>("VBoxContainer");

		var adminButton = buttons.GetNode<Button>("Button"); //
		var playerButton = buttons.GetNode<Button>("Button2"); //

		adminButton.Pressed += OnAdminSelected;
		playerButton.Pressed += OnPlayerSelected;
	}

	private void OnAdminSelected()
	{
		GD.Print("Вход как админ");
		GetTree().ChangeSceneToFile("res://AdminUI.tscn");
	}
	
	private void OnPlayerSelected()
	{
		GD.Print("Вход как игрок");
		GetTree().ChangeSceneToFile("res://PlayerUI.tscn");
	}
}
