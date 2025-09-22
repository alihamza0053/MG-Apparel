const bcrypt = require('bcryptjs');

async function generatePasswordHash() {
    try {
        const password = 'hamza123';
        const saltRounds = 10;
        
        console.log('Generating hash for password:', password);
        
        // Generate hash
        const hash = await bcrypt.hash(password, saltRounds);
        console.log('Generated hash:', hash);
        
        // Test verification
        const isValid = await bcrypt.compare(password, hash);
        console.log('Hash verification test:', isValid);
        
        // Generate SQL update statement
        console.log('\n--- COPY THIS SQL TO SUPABASE ---');
        console.log(`UPDATE users SET password = '${hash}';`);
        console.log('--- END SQL ---\n');
        
    } catch (error) {
        console.error('Error generating hash:', error);
    }
}

generatePasswordHash();
