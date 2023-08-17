import 'package:flutter/material.dart';

class PatientCard extends StatefulWidget {
  final String name;
  final String photoUrl;
  final String bedNumber;
  final String roomNumber;
  final int age;
  final bool isInRoom;
  final bool isInBed;

  const PatientCard({
    required this.name,
    required this.photoUrl,
    required this.bedNumber,
    required this.roomNumber,
    required this.age,
    required this.isInRoom,
    required this.isInBed,
  });

  @override
  _PatientCardState createState() => _PatientCardState();
}

class _PatientCardState extends State<PatientCard> {
  List<bool> _isSelected = [];

  @override
  void initState() {
    super.initState();
    _isSelected = [widget.isInRoom, widget.isInBed];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(widget.photoUrl),
        ),
        title: Text(widget.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bed: ${widget.bedNumber}, Room: ${widget.roomNumber}'),
            Text('Age: ${widget.age}'),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Adjust alignment as needed
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.isInRoom ? Icons.check_circle : Icons.cancel,
                        color: widget.isInRoom ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text('In Room: ${widget.isInRoom ? 'Yes' : 'No'}'),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        widget.isInBed ? Icons.check_circle : Icons.cancel,
                        color: widget.isInBed ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text('In Bed: ${widget.isInBed ? 'Yes' : 'No'}'),
                    ],
                  ),
                ]
            )
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, IconData icon, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4), // Add horizontal margin
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _isSelected[index] ? Colors.blue : Colors.black), // Change icon color based on selected state
          SizedBox(width: 4), // Add small spacing between icon and text
          Text(
            label,
            style: TextStyle(
              color: _isSelected[index] ? Colors.blue : Colors.black, // Change text color based on selected state
              fontWeight: _isSelected[index] ? FontWeight.bold : FontWeight.normal, // Bold font weight when selected
            ),
          ),
        ],
      ),
    );
  }

}
