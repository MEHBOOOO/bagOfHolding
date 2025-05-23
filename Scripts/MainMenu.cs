using Godot;
using System;

public partial class MainMenu : Control
{
public override void _Ready()
{
	var serverButtons = GetNode<VBoxContainer>("VBoxContainer");

	foreach (Node node in serverButtons.GetChildren())
	{
		if (node is Button button)
		{
			button.Pressed += () => OnServerSelected(button.Text);
		}
	}
}

	private void OnServerSelected(string serverName)
	{
		GD.Print($"Сервер выбран: {serverName}");

		GetTree().ChangeSceneToFile("res://scenes/LoginMenu.tscn");
	}
	
	
	private void OnBackPressed()
	{
		GD.Print("Назад к выбору сервера");
		GetTree().ChangeSceneToFile("res://Scenes/MainMenu.tscn");
	}
}
