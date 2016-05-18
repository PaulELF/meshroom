#pragma once

#include <QAbstractListModel>
#include <QJsonArray>
#include "Node.hpp"

namespace nodeeditor
{

class NodeModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum NodeRoles
    {
        NameRole = Qt::UserRole + 1,
        InputsRole,
        OutputsRole,
        XRole,
        YRole,
        ModelDataRole
    };

public:
    NodeModel(QObject* parent = 0);
    NodeModel(const NodeModel& obj) = delete;
    NodeModel& operator=(NodeModel const&) = delete;

public:
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex& index, const QVariant& value, int role) override;
    Node* get(const QString& name);

public:
    Q_SLOT void addNode(Node* node);
    Q_SLOT void addNode(const QJsonObject& descriptor);
    Q_SLOT QVariantMap get(int row) const;
    Q_SLOT QJsonArray serializeToJSON() const;
    Q_SLOT void deserializeFromJSON(const QJsonArray&);
    Q_SIGNAL void countChanged(int c);

protected:
    QHash<int, QByteArray> roleNames() const override;

private:
    QList<Node*> _nodes;
};

} // namespace