import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:app_autonomo/Navegacion/drawer.dart';

class NotesScreen extends StatefulWidget {
  final String userId; // Recibimos el userId para el Drawer y la referencia en Firebase

  NotesScreen({required this.userId});

  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late DatabaseReference notesRef;

  @override
  void initState() {
    super.initState();
    notesRef = FirebaseDatabase.instance.ref('users/${widget.userId}/notes');
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await notesRef.child(noteId).remove();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nota eliminada correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la nota: $e')),
      );
    }
  }

  void editNote(String noteId, String title, String description, double price) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNoteScreen(
          userId: widget.userId,
          noteId: noteId,
          initialTitle: title,
          initialDescription: description,
          initialPrice: price,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mis Notas",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: MyDrawer(userId: widget.userId),
      body: StreamBuilder(
        stream: notesRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar las notas'));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: Text(
                'No tienes notas guardadas.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
            );
          }

          Map<dynamic, dynamic> notes = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<Widget> noteWidgets = [];

          notes.forEach((key, value) {
            noteWidgets.add(Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: Text(
                  value['title'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Precio: \$${value['price']}',
                  style: TextStyle(color: Colors.black54),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: () => editNote(
                        key,
                        value['title'],
                        value['description'],
                        value['price'],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => deleteNote(key),
                    ),
                  ],
                ),
              ),
            ));
          });

          return ListView(
            children: noteWidgets,
          );
        },
      ),
    );
  }
}

class EditNoteScreen extends StatelessWidget {
  final String userId;
  final String noteId;
  final String initialTitle;
  final String initialDescription;
  final double initialPrice;

  EditNoteScreen({
    required this.userId,
    required this.noteId,
    required this.initialTitle,
    required this.initialDescription,
    required this.initialPrice,
  });

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController(text: initialTitle);
    final descriptionController = TextEditingController(text: initialDescription);
    final priceController = TextEditingController(text: initialPrice.toString());

    Future<void> updateNote() async {
      final title = titleController.text;
      final description = descriptionController.text;
      final price = double.tryParse(priceController.text) ?? 0.0;

      if (title.isEmpty || description.isEmpty || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor, completa todos los campos')),
        );
        return;
      }

      try {
        DatabaseReference noteRef = FirebaseDatabase.instance.ref('users/$userId/notes/$noteId');
        await noteRef.update({
          'title': title,
          'description': description,
          'price': price,
        });

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar la nota: $e')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Editar Nota"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Título',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Precio',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Actualizar Nota",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
