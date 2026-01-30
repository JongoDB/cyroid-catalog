# CYROID Catalog

Training content catalog for [CYROID](https://github.com/JongoDB/CYROID) (Cyber Range Orchestrator In Docker).

Browse and install range blueprints, scenarios, VM images, and training content into your CYROID instance.

## Structure

```
cyroid-catalog/
├── catalog.yaml          # Catalog metadata
├── index.json            # Auto-generated item index
├── blueprints/           # Self-contained range packages
├── scenarios/            # Standalone scenario timelines
├── images/               # Shared Dockerfile projects
├── base-images/          # VM base image definitions
└── scripts/              # Index generation tooling
```

## Usage

### In CYROID

Add this repository as a catalog source in your CYROID instance:

1. Navigate to **Admin Settings > Catalog Sources**
2. Add a new source with URL: `https://github.com/JongoDB/cyroid-catalog.git`
3. Click **Sync** to fetch the catalog index
4. Browse available content in the **Content Catalog** page

### Self-Hosted / Air-Gapped

Clone this repo and point your CYROID instance at the local path:

```bash
git clone https://github.com/JongoDB/cyroid-catalog.git /data/cyroid-catalog
```

Then configure the catalog source as type `local` with the clone path.

## Contributing

To add new content to the catalog, see [CONTRIBUTING.md](CONTRIBUTING.md) (coming soon).

## License

See [LICENSE](LICENSE).
