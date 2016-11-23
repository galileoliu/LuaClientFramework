/* 
 LuaFramework Code By Jarjin lee 
*/

public interface IMessage
{
	string Name { get; }

	object Body { get; set; }
		
	string Type { get; set; }

    string ToString();
}

