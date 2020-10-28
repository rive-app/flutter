import 'package:admin/manager.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/model.dart';
import 'package:rive_editor/widgets/notifications.dart';

class Announcements extends StatefulWidget {
  final int ownerId;

  const Announcements({Key key, this.ownerId = 0}) : super(key: key);

  @override
  _AnnouncementsState createState() => _AnnouncementsState();
}

class _AnnouncementsState extends State<Announcements> {
  void clear() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: AnnouncementList(clear: clear),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: AnnouncementForm(clear: clear),
            ),
          )
        ],
      ),
    );
  }
}

class AnnouncementList extends StatelessWidget {
  final Function clear;

  const AnnouncementList({Key key, this.clear}) : super(key: key);

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Announcement>>(
      future: AdminManager.instance.getAnnouncements(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView(children: [
            for (final e in snapshot.data) ...[
              const SizedBox(height: 30),
              FlatButton(
                child: const Text('Delete below'),
                onPressed: () => {
                  AdminManager.instance
                      .cancelAnnoucement(e.id)
                      .then<dynamic>((value) => clear())
                },
              ),
              NotificationCard(
                child: AnnouncementNotification(e),
              )
            ]
          ]);
        } else {
          return const CircularProgressIndicator();
        }
      });
}

class AnnouncementForm extends StatefulWidget {
  final Function clear;
  const AnnouncementForm({Key key, this.clear}) : super(key: key);
  @override
  AnnouncementFormState createState() {
    return AnnouncementFormState();
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class AnnouncementFormState extends State<AnnouncementForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<AnnouncementFormState>.
  final _formKey = GlobalKey<FormState>();
  bool enabled = true;

  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  final validFromController =
      TextEditingController(text: DateTime.now().toIso8601String());
  final validToController = TextEditingController(
      text: DateTime.now().add(const Duration(hours: 12)).toIso8601String());
  String title = '';
  String body = '';
  DateTime parsedValidFrom;
  DateTime parsedValidTo;

  void changed(String change) {
    setState(() {
      title = titleController.text;
      body = bodyController.text;
      try {
        parsedValidFrom = DateTime.parse(validFromController.text).toUtc();
      } on Exception {
        parsedValidFrom = null;
      }
      try {
        parsedValidTo = DateTime.parse(validToController.text).toUtc();
      } on Exception {
        parsedValidTo = null;
      }
    });
  }

  void setEnable(bool _enabled) {
    setState(() {
      enabled = _enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            onChanged: changed,
            controller: titleController,
            decoration:
                const InputDecoration(labelText: 'Title of the annoucement.'),
            validator: (String value) {
              if (value.isEmpty) {
                return 'Cannot be empty';
              }
              return null;
            },
          ),
          TextFormField(
            onChanged: changed,
            controller: bodyController,
            maxLines: 10,
            decoration: const InputDecoration(
                labelText: 'body of the message in markdown!'),
            validator: (String value) {
              if (value.isEmpty) {
                return 'Cannot be empty';
              }
              return null;
            },
          ),
          TextFormField(
            onChanged: changed,
            controller: validFromController,
            decoration: const InputDecoration(
                labelText: 'This message will appear aftersdf!'),
            validator: (String value) {
              if (value.isEmpty) {
                return 'Cannot be empty';
              }
              try {
                DateTime.parse(value);
              } on Exception {
                return 'bad date time';
              }
              return null;
            },
          ),
          TextFormField(
            onChanged: changed,
            controller: validToController,
            decoration: const InputDecoration(
                labelText: 'This message will appear aftersdf!'),
            validator: (String value) {
              if (value.isEmpty) {
                return 'Cannot be empty';
              }
              try {
                DateTime.parse(value);
              } on Exception {
                return 'bad date time';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          NotificationCard(
            child: AnnouncementNotification(
                Announcement(title: title, body: body)),
          ),
          Row(
            children: [
              Expanded(child: Text('Valid from')),
              Text('${parsedValidFrom?.toIso8601String()}'),
            ],
          ),
          Row(
            children: [
              Expanded(child: Text('Valid to')),
              Text('${parsedValidTo?.toIso8601String()}'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: RaisedButton(
              onPressed: enabled
                  ? () {
                      setEnable(false);
                      // Validate returns true if the form is valid, or false
                      // otherwise.
                      if (_formKey.currentState.validate()) {
                        // If the form is valid, display a Snackbar.
                        Scaffold.of(context).showSnackBar(
                            const SnackBar(content: Text('Processing Data')));

                        AdminManager.instance.addAnnouncement(
                          title: titleController.text,
                          body: bodyController.text,
                          validFrom: validFromController.text,
                          validTo: validToController.text,
                        );
                        widget.clear();
                      }

                      setEnable(true);
                    }
                  : null,
              child: const Text('Create Announcement!'),
            ),
          ),
        ],
      ),
    );
  }
}
