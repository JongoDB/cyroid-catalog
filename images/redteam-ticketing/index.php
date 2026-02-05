<?php
// CYROID Red Team Lab - Simple Ticketing System
// WARNING: Intentionally vulnerable for training purposes

$tickets = json_decode(file_get_contents('tickets/tickets.json'), true);
?>
<!DOCTYPE html>
<html>
<head>
    <title>ACME Widgets - IT Helpdesk</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        h1 { color: #333; border-bottom: 2px solid #007bff; padding-bottom: 10px; }
        .ticket { background: white; padding: 15px; margin: 10px 0; border-radius: 5px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        .ticket-header { display: flex; justify-content: space-between; border-bottom: 1px solid #eee; padding-bottom: 10px; }
        .ticket-id { font-weight: bold; color: #007bff; }
        .ticket-status { padding: 3px 10px; border-radius: 3px; font-size: 12px; }
        .status-open { background: #ffc107; color: #333; }
        .status-closed { background: #28a745; color: white; }
        .ticket-body { padding: 10px 0; }
        .ticket-meta { color: #666; font-size: 12px; }
        .warning { background: #fff3cd; border: 1px solid #ffc107; padding: 10px; margin: 10px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>ACME Widgets IT Helpdesk</h1>

        <div class="warning">
            <strong>Internal System:</strong> This ticketing system is for internal use only.
            Do not share ticket information outside the organization.
        </div>

        <h2>Recent Tickets</h2>

        <?php foreach ($tickets as $ticket): ?>
        <div class="ticket">
            <div class="ticket-header">
                <span class="ticket-id">#<?= htmlspecialchars($ticket['id']) ?></span>
                <span class="ticket-status status-<?= $ticket['status'] ?>"><?= ucfirst($ticket['status']) ?></span>
            </div>
            <div class="ticket-body">
                <strong><?= htmlspecialchars($ticket['subject']) ?></strong>
                <p><?= nl2br(htmlspecialchars($ticket['description'])) ?></p>
            </div>
            <div class="ticket-meta">
                Submitted by: <?= htmlspecialchars($ticket['user']) ?> |
                Date: <?= htmlspecialchars($ticket['date']) ?> |
                Assigned: <?= htmlspecialchars($ticket['assigned']) ?>
            </div>
        </div>
        <?php endforeach; ?>
    </div>
</body>
</html>
