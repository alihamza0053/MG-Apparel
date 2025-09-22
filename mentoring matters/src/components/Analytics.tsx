import React, { useState, useEffect } from 'react';
import { supabase } from '../supabaseClient';
import { useAuth } from '../AuthContext';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, PieChart, Pie, Cell, ResponsiveContainer } from 'recharts';
import { Download, Users, Target, MessageSquare, BookOpen, TrendingUp } from 'lucide-react';

interface AnalyticsData {
  totalPairs: number;
  activePairs: number;
  totalGoals: number;
  completedGoals: number;
  totalFeedback: number;
  averageRating: number;
  totalMaterials: number;
}

export function Analytics() {
  const { user } = useAuth();
  const [data, setData] = useState<AnalyticsData>({
    totalPairs: 0,
    activePairs: 0,
    totalGoals: 0,
    completedGoals: 0,
    totalFeedback: 0,
    averageRating: 0,
    totalMaterials: 0
  });
  const [chartData, setChartData] = useState<any[]>([]);
  const [pieData, setPieData] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  // Function to generate real monthly trends data
  const generateMonthlyTrends = async (pairs: any[], goals: any[], feedback: any[]) => {
    const currentDate = new Date();
    const currentYear = currentDate.getFullYear();
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const monthlyData = [];

    // Get data for the last 6 months
    for (let i = 5; i >= 0; i--) {
      const targetDate = new Date(currentYear, currentDate.getMonth() - i, 1);
      const targetMonth = targetDate.getMonth();
      const targetYear = targetDate.getFullYear();
      const monthName = monthNames[targetMonth];

      // Count pairs created in this month
      const pairsInMonth = pairs?.filter(pair => {
        if (!pair.created_at) return false;
        const pairDate = new Date(pair.created_at);
        return pairDate.getMonth() === targetMonth && pairDate.getFullYear() === targetYear;
      }).length || 0;

      // Count goals created in this month
      const goalsInMonth = goals?.filter(goal => {
        if (!goal.created_at) return false;
        const goalDate = new Date(goal.created_at);
        return goalDate.getMonth() === targetMonth && goalDate.getFullYear() === targetYear;
      }).length || 0;

      // Count feedback submitted in this month
      const feedbackInMonth = feedback?.filter(fb => {
        if (!fb.created_at) return false;
        const feedbackDate = new Date(fb.created_at);
        return feedbackDate.getMonth() === targetMonth && feedbackDate.getFullYear() === targetYear;
      }).length || 0;

      monthlyData.push({
        month: monthName,
        pairs: pairsInMonth,
        goals: goalsInMonth,
        feedback: feedbackInMonth
      });
    }

    return monthlyData;
  };

  useEffect(() => {
    if (user?.role === 'admin') {
      fetchAnalytics();
    }
  }, [user]);

  const fetchAnalytics = async () => {
    try {
      // Fetch mentoring pairs
      const { data: pairs, error: pairsError } = await supabase
        .from('mentoring_pairs')
        .select('*')
        .eq('organization_id', user?.organization_id);

      if (pairsError) throw pairsError;

      const pairIds = pairs?.map(p => p.id) || [];
      const activePairs = pairs?.filter(p => p.status === 'active') || [];

      // Fetch goals
      const { data: goals, error: goalsError } = await supabase
        .from('goals')
        .select('*')
        .in('pair_id', pairIds);

      if (goalsError) throw goalsError;

      const completedGoals = goals?.filter(g => g.status === 'completed') || [];

      // Fetch feedback
      // Fetch real feedback data
      const { data: feedback, error: feedbackError } = await supabase
        .from('feedback')
        .select('rating, created_at');

      if (feedbackError) {
        console.log('Feedback error:', feedbackError);
      }

      // Calculate average rating from real feedback data
      const realFeedback = feedback || [];
      const averageRating = realFeedback.length > 0 
        ? realFeedback.reduce((sum, f) => sum + (f.rating || 0), 0) / realFeedback.length 
        : 0;

      // Fetch materials
      const { data: materials, error: materialsError } = await supabase
        .from('materials')
        .select('*')
        .in('pair_id', pairIds);

      if (materialsError) throw materialsError;

      // Set analytics data
      setData({
        totalPairs: pairs?.length || 0,
        activePairs: activePairs.length,
        totalGoals: goals?.length || 0,
        completedGoals: completedGoals.length,
        totalFeedback: realFeedback.length,
        averageRating: parseFloat(averageRating.toFixed(1)),
        totalMaterials: materials?.length || 0
      });

      // Chart data for goals progress
      const goalStatusData = [
        { name: 'Not Started', value: goals?.filter(g => g.status === 'not_started').length || 0 },
        { name: 'In Progress', value: goals?.filter(g => g.status === 'in_progress').length || 0 },
        { name: 'Completed', value: completedGoals.length }
      ];

      // Generate real monthly data based on actual database records
      const monthlyData = await generateMonthlyTrends(pairs, goals, realFeedback);

      setChartData(monthlyData);
      setPieData(goalStatusData);

    } catch (error) {
      console.error('Error fetching analytics:', error);
    } finally {
      setLoading(false);
    }
  };

  const exportToCSV = () => {
    const csvData = [
      ['Metric', 'Value'],
      ['Total Mentoring Pairs', data.totalPairs],
      ['Active Pairs', data.activePairs],
      ['Total Goals', data.totalGoals],
      ['Completed Goals', data.completedGoals],
      ['Total Feedback', data.totalFeedback],
      ['Average Rating', data.averageRating],
      ['Total Materials', data.totalMaterials]
    ];

    const csvContent = csvData.map(row => row.join(',')).join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', 'mentoring_analytics.csv');
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  if (user?.role !== 'admin') {
    return (
      <div style={{
        background: 'white',
        padding: 40,
        borderRadius: 12,
        boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
        textAlign: 'center'
      }}>
        <h3 style={{
          fontSize: 18,
          fontWeight: 600,
          color: '#374151',
          margin: '0 0 8px 0'
        }}>
          Access Denied
        </h3>
        <p style={{
          color: '#64748b',
          margin: 0,
          fontSize: 14
        }}>
          Only administrators can view analytics.
        </p>
      </div>
    );
  }

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: 40 }}>
        <div style={{
          width: 40,
          height: 40,
          border: '4px solid #e2e8f0',
          borderTop: '4px solid #3b82f6',
          borderRadius: '50%',
          animation: 'spin 1s linear infinite',
          margin: '0 auto 16px'
        }} />
        <p style={{ color: '#64748b' }}>Loading analytics...</p>
      </div>
    );
  }

  const colors = ['#ef4444', '#f59e0b', '#22c55e'];

  return (
    <div>
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 32
      }}>
        <div>
          <h1 style={{
            fontSize: 24,
            fontWeight: 'bold',
            color: '#1e40af',
            margin: 0,
            marginBottom: 4
          }}>
            Analytics Dashboard
          </h1>
          <p style={{
            color: '#64748b',
            margin: 0,
            fontSize: 14
          }}>
            Overview of mentoring program performance
          </p>
        </div>
        
        <button
          onClick={exportToCSV}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 8,
            padding: '12px 16px',
            background: '#22c55e',
            color: 'white',
            border: 'none',
            borderRadius: 8,
            cursor: 'pointer',
            fontSize: 14,
            fontWeight: 500
          }}
        >
          <Download size={16} />
          Export CSV
        </button>
      </div>

      {/* Key Metrics */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: 20,
        marginBottom: 32
      }}>
        <div style={{
          background: 'white',
          padding: 20,
          borderRadius: 12,
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
          borderLeft: '4px solid #3b82f6'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 8 }}>
            <Users size={20} color="#3b82f6" />
            <span style={{ fontSize: 14, fontWeight: 500, color: '#64748b' }}>Active Pairs</span>
          </div>
          <div style={{ fontSize: 24, fontWeight: 'bold', color: '#1f2937' }}>
            {data.activePairs}/{data.totalPairs}
          </div>
        </div>

        <div style={{
          background: 'white',
          padding: 20,
          borderRadius: 12,
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
          borderLeft: '4px solid #22c55e'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 8 }}>
            <Target size={20} color="#22c55e" />
            <span style={{ fontSize: 14, fontWeight: 500, color: '#64748b' }}>Goal Completion</span>
          </div>
          <div style={{ fontSize: 24, fontWeight: 'bold', color: '#1f2937' }}>
            {data.totalGoals > 0 ? Math.round((data.completedGoals / data.totalGoals) * 100) : 0}%
          </div>
        </div>

        <div style={{
          background: 'white',
          padding: 20,
          borderRadius: 12,
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
          borderLeft: '4px solid #f59e0b'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 8 }}>
            <MessageSquare size={20} color="#f59e0b" />
            <span style={{ fontSize: 14, fontWeight: 500, color: '#64748b' }}>Avg Rating</span>
          </div>
          <div style={{ fontSize: 24, fontWeight: 'bold', color: '#1f2937' }}>
            {data.averageRating}/5
          </div>
        </div>

        <div style={{
          background: 'white',
          padding: 20,
          borderRadius: 12,
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
          borderLeft: '4px solid #8b5cf6'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 8 }}>
            <BookOpen size={20} color="#8b5cf6" />
            <span style={{ fontSize: 14, fontWeight: 500, color: '#64748b' }}>Materials Shared</span>
          </div>
          <div style={{ fontSize: 24, fontWeight: 'bold', color: '#1f2937' }}>
            {data.totalMaterials}
          </div>
        </div>
      </div>

      {/* Charts */}
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: 24, marginBottom: 32 }}>
        {/* Bar Chart */}
        <div style={{
          background: 'white',
          padding: 24,
          borderRadius: 12,
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)'
        }}>
          <h3 style={{
            fontSize: 18,
            fontWeight: 600,
            color: '#374151',
            margin: '0 0 20px 0'
          }}>
            Monthly Trends
          </h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Bar dataKey="pairs" fill="#3b82f6" name="Pairs" />
              <Bar dataKey="goals" fill="#22c55e" name="Goals" />
              <Bar dataKey="feedback" fill="#f59e0b" name="Feedback" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Pie Chart */}
        <div style={{
          background: 'white',
          padding: 24,
          borderRadius: 12,
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)'
        }}>
          <h3 style={{
            fontSize: 18,
            fontWeight: 600,
            color: '#374151',
            margin: '0 0 20px 0'
          }}>
            Goal Status
          </h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={pieData}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, percent }: any) => `${name} ${((percent || 0) * 100).toFixed(0)}%`}
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
              >
                {pieData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={colors[index % colors.length]} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Summary Stats */}
      <div style={{
        background: 'white',
        padding: 24,
        borderRadius: 12,
        boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)'
      }}>
        <h3 style={{
          fontSize: 18,
          fontWeight: 600,
          color: '#374151',
          margin: '0 0 16px 0'
        }}>
          Program Summary
        </h3>
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))',
          gap: 16
        }}>
          <div>
            <div style={{ fontSize: 12, color: '#64748b', marginBottom: 4 }}>Total Pairs</div>
            <div style={{ fontSize: 20, fontWeight: 'bold', color: '#1f2937' }}>{data.totalPairs}</div>
          </div>
          <div>
            <div style={{ fontSize: 12, color: '#64748b', marginBottom: 4 }}>Total Goals</div>
            <div style={{ fontSize: 20, fontWeight: 'bold', color: '#1f2937' }}>{data.totalGoals}</div>
          </div>
          <div>
            <div style={{ fontSize: 12, color: '#64748b', marginBottom: 4 }}>Completed Goals</div>
            <div style={{ fontSize: 20, fontWeight: 'bold', color: '#1f2937' }}>{data.completedGoals}</div>
          </div>
          <div>
            <div style={{ fontSize: 12, color: '#64748b', marginBottom: 4 }}>Total Feedback</div>
            <div style={{ fontSize: 20, fontWeight: 'bold', color: '#1f2937' }}>{data.totalFeedback}</div>
          </div>
          <div>
            <div style={{ fontSize: 12, color: '#64748b', marginBottom: 4 }}>Materials Shared</div>
            <div style={{ fontSize: 20, fontWeight: 'bold', color: '#1f2937' }}>{data.totalMaterials}</div>
          </div>
        </div>
      </div>
    </div>
  );
}