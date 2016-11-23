/* 
 LuaFramework Code By Jarjin lee
*/

using System;
using System.Collections.Generic;

public class Controller : IController
{
    protected IDictionary<string, Type> m_cmdMap;
    protected IDictionary<IView, List<string>> m_viewCmdMap;

    protected static volatile IController m_instance;
    protected readonly object m_syncRoot = new object();
    protected static readonly object m_staticSyncRoot = new object();

    protected Controller()
    {
        InitializeController();
    }

    static Controller()
    {
    }

    public static IController Instance
    {
        get
        {
            if (m_instance == null)
            {
                lock (m_staticSyncRoot)
                {
                    if (m_instance == null)
                    {
                        m_instance = new Controller();
                    }
                }
            }
            return m_instance;
        }
    }

    protected virtual void InitializeController()
    {
        m_cmdMap = new Dictionary<string, Type>();
        m_viewCmdMap = new Dictionary<IView, List<string>>();
    }

    public virtual void ExecuteCommand(IMessage message)
    {
        Type commandType = null;
        List<IView> views = null;
        lock (m_syncRoot)
        {
            if (m_cmdMap.ContainsKey(message.Name))
            {
                commandType = m_cmdMap[message.Name];
            }
            else
            {
                views = new List<IView>();
                foreach (var pair in m_viewCmdMap)
                {
                    if (pair.Value.Contains(message.Name))
                    {
                        views.Add(pair.Key);
                    }
                }
            }
        }
        if (commandType != null)
        {  
            //Direct command.
            object commandInstance = Activator.CreateInstance(commandType);
            if (commandInstance is ICommand)
            {
                ((ICommand)commandInstance).Execute(message);
            }
        }
        if (views != null && views.Count > 0)
        {
            for (int i = 0; i < views.Count; i++)
            {
                views[i].OnMessage(message);
            }
            views = null;
        }
    }

    public virtual void RegisterCommand(string commandName, Type commandType)
    {
        lock (m_syncRoot)
        {
            m_cmdMap[commandName] = commandType;
        }
    }

    public virtual void RegisterViewCommand(IView view, string[] commandNames)
    {
        lock (m_syncRoot)
        {
            if (m_viewCmdMap.ContainsKey(view))
            {
                List<string> list = null;
                if (m_viewCmdMap.TryGetValue(view, out list))
                {
                    for (int i = 0; i < commandNames.Length; i++)
                    {
                        if (list.Contains(commandNames[i]))
                        {
                            continue;
                        }
                        list.Add(commandNames[i]);
                    }
                }
            }
            else
            {
                m_viewCmdMap.Add(view, new List<string>(commandNames));
            }
        }
    }

    public virtual bool HasCommand(string commandName)
    {
        lock (m_syncRoot)
        {
            return m_cmdMap.ContainsKey(commandName);
        }
    }

    public virtual void RemoveCommand(string commandName)
    {
        lock (m_syncRoot)
        {
            if (m_cmdMap.ContainsKey(commandName))
            {
                m_cmdMap.Remove(commandName);
            }
        }
    }

    public virtual void RemoveViewCommand(IView view, string[] commandNames)
    {
        lock (m_syncRoot)
        {
            if (m_viewCmdMap.ContainsKey(view))
            {
                List<string> list = null;
                if (m_viewCmdMap.TryGetValue(view, out list))
                {
                    for (int i = 0; i < commandNames.Length; i++)
                    {
                        if (!list.Contains(commandNames[i])) continue;
                        list.Remove(commandNames[i]);
                    }
                }
            }
        }
    }
}