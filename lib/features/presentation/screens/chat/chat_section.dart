import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatUser {
  final String id;
  final String name;
  final String lastMessage;
  final String timestamp;
  final bool isOnline;
  final Color avatarColor;

  ChatUser({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.timestamp,
    required this.isOnline,
    required this.avatarColor,
  });
}

class ChatSection extends StatefulWidget {
  const ChatSection({super.key});

  @override
  State<ChatSection> createState() => _ChatSectionState();
}

class _ChatSectionState extends State<ChatSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<ChatUser> _users = [
    ChatUser(
      id: '1',
      name: 'Emma Johnson',
      lastMessage: 'Hey there! How are you?',
      timestamp: '2:30 PM',
      isOnline: true,
      avatarColor: Colors.blue,
    ),
    ChatUser(
      id: '2',
      name: 'Michael Smith',
      lastMessage: 'Meeting at 3 PM tomorrow',
      timestamp: '1:45 PM',
      isOnline: false,
      avatarColor: Colors.green,
    ),
    ChatUser(
      id: '3',
      name: 'Sophia Williams',
      lastMessage: 'Did you see the new project?',
      timestamp: '12:20 PM',
      isOnline: true,
      avatarColor: Colors.purple,
    ),
    ChatUser(
      id: '4',
      name: 'James Brown',
      lastMessage: 'Lunch tomorrow?',
      timestamp: '11:15 AM',
      isOnline: false,
      avatarColor: Colors.orange,
    ),
    ChatUser(
      id: '5',
      name: 'Olivia Davis',
      lastMessage: 'Call me when you\'re free',
      timestamp: '10:30 AM',
      isOnline: true,
      avatarColor: Colors.pink,
    ),
  ];

  List<ChatUser> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      return user.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _openUserChat(ChatUser user, BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7),],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "Chats",
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary,),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),

          // 👥 Users List
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      size: 50, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    'No users found',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor:
                        user.avatarColor.withValues(alpha: 0.2),
                        child: Text(
                          user.name[0],
                          style: TextStyle(
                            color: user.avatarColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (user.isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    user.lastMessage,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 14),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        user.timestamp,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (user.isOnline)
                        Text(
                          'Online',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600),
                        ),
                    ],
                  ),
                  onTap: () => _openUserChat(user, context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
