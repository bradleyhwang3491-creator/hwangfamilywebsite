import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { MapContainer, Marker, TileLayer } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import BottomNav from '../components/BottomNav';
import { supabase } from '../lib/supabaseClient';

interface TravelRecordRow {
  id: string;
  title: string;
  region: string;
  address: string;
  country: string | null;
  lat: number | null;
  lng: number | null;
  is_domestic: boolean | null;
  start_date: string;
  end_date: string;
}

interface PinRecord {
  id: string;
  title: string;
  start_date: string;
  end_date: string;
  region: string;
  address: string;
  thumbnailUrl: string | null;
}

interface MapPin {
  key: string;
  lat: number;
  lng: number;
  region: string;
  country: string | null;
  records: PinRecord[];
}

const markerIcon = L.divIcon({
  className: '',
  html: '<div style="width:16px;height:16px;border-radius:9999px;background:#111827;border:2px solid #FFFFFF;box-shadow:0 1px 3px rgba(0,0,0,.35)"></div>',
  iconSize: [16, 16],
  iconAnchor: [8, 8],
});

function daysBetween(start: string, end: string) {
  const ms = new Date(end).getTime() - new Date(start).getTime();
  return Math.round(ms / 86_400_000) + 1;
}

export default function TravelPage() {
  const navigate = useNavigate();
  const [records, setRecords] = useState<TravelRecordRow[]>([]);
  const [thumbnails, setThumbnails] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [selectedKey, setSelectedKey] = useState<string | null>(null);

  useEffect(() => {
    supabase
      .from('travel_records')
      .select('id, title, region, address, country, lat, lng, is_domestic, start_date, end_date')
      .order('start_date', { ascending: false })
      .then(({ data }) => {
        if (data) setRecords(data);
        setLoading(false);
      });

    supabase
      .from('travel_record_photos')
      .select('travel_record_id, storage_path, sort_order')
      .order('sort_order', { ascending: true })
      .then(({ data }) => {
        if (!data) return;
        const first: Record<string, string> = {};
        for (const row of data) {
          if (first[row.travel_record_id]) continue;
          first[row.travel_record_id] = supabase.storage.from('travel-photos').getPublicUrl(row.storage_path).data
            .publicUrl;
        }
        setThumbnails(first);
      });
  }, []);

  const summary = useMemo(() => {
    const countries = new Set(records.map((r) => r.country).filter(Boolean));
    const regions = new Set(records.map((r) => r.region));
    const domesticDays = records
      .filter((r) => r.is_domestic)
      .reduce((sum, r) => sum + daysBetween(r.start_date, r.end_date), 0);
    const overseasDays = records
      .filter((r) => r.is_domestic === false)
      .reduce((sum, r) => sum + daysBetween(r.start_date, r.end_date), 0);
    return {
      countryCount: countries.size,
      regionCount: regions.size,
      domesticDays,
      overseasDays,
      totalDays: domesticDays + overseasDays,
    };
  }, [records]);

  const pins = useMemo(() => {
    // Group by region name (not raw coordinates): the same place visited on
    // different trips should always collapse into one mark, even if the
    // geocoded address text — and therefore lat/lng — differs slightly.
    const groups = new Map<string, MapPin>();
    for (const r of records) {
      if (r.lat == null || r.lng == null) continue;
      const key = `${r.country ?? ''}__${r.region.trim().toLowerCase()}`;
      const recordRef: PinRecord = {
        id: r.id,
        title: r.title,
        start_date: r.start_date,
        end_date: r.end_date,
        region: r.region,
        address: r.address,
        thumbnailUrl: thumbnails[r.id] ?? null,
      };
      const existing = groups.get(key);
      if (existing) {
        existing.records.push(recordRef);
      } else {
        groups.set(key, {
          key,
          lat: r.lat,
          lng: r.lng,
          region: r.region,
          country: r.country,
          records: [recordRef],
        });
      }
    }
    return [...groups.values()];
  }, [records, thumbnails]);

  const selectedPin = pins.find((p) => p.key === selectedKey) ?? null;

  return (
    <div className="app-frame">
      <header className="safe-top px-5 pt-4 pb-3 bg-white border-b border-gray-border flex items-center gap-2">
        <button
          type="button"
          onClick={() => navigate('/home')}
          aria-label="홈으로"
          className="w-9 h-9 -ml-1.5 rounded-full flex items-center justify-center text-text-900 text-[18px]"
        >
          ←
        </button>
        <h1 className="text-[20px] font-bold text-text-900">여행 기록하기</h1>
      </header>

      <main className="flex-1 overflow-y-auto px-5 pt-4 pb-28 flex flex-col gap-6">
        {/* 영역 1: 여행기록하기 */}
        <button
          onClick={() => navigate('/travel/new')}
          className="w-full py-4 rounded-2xl text-white text-[15px] font-semibold flex items-center justify-center gap-1.5"
          style={{ background: '#111827', boxShadow: 'var(--shadow-card)' }}
        >
          <span className="text-[17px] leading-none">+</span>
          여행기록하기
        </button>

        {/* 영역 2: 여행 종합 리뷰 */}
        <section>
          <h2 className="text-[16px] font-bold text-text-900 mb-3">여행 종합 리뷰</h2>

          <div className="grid grid-cols-3 gap-2 mb-2">
            <StatCard label="방문 국가" value={`${summary.countryCount}개국`} />
            <StatCard label="방문 지역" value={`${summary.regionCount}곳`} />
            <StatCard label="총 여행일" value={`${summary.totalDays}일`} />
          </div>

          <div className="flex gap-2 mb-4">
            <SubStat label="한국" value={`${summary.domesticDays}일`} />
            <SubStat label="해외" value={`${summary.overseasDays}일`} />
          </div>

          <div
            className="rounded-2xl overflow-hidden border border-gray-border"
            style={{ height: 320, boxShadow: 'var(--shadow-card)' }}
          >
            <MapContainer
              center={[30, 128]}
              zoom={3}
              scrollWheelZoom
              style={{ height: '100%', width: '100%' }}
            >
              <TileLayer
                attribution='&copy; OpenStreetMap contributors &copy; CARTO'
                url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png"
              />
              {pins.map((pin) => (
                <Marker
                  key={pin.key}
                  position={[pin.lat, pin.lng]}
                  icon={markerIcon}
                  eventHandlers={{ click: () => setSelectedKey(pin.key) }}
                />
              ))}
            </MapContainer>
          </div>

          {!loading && records.length === 0 && (
            <p className="text-[13px] text-text-400 text-center mt-4">
              아직 등록된 여행 기록이 없어요. 첫 기록을 남겨보세요!
            </p>
          )}

          {selectedPin && (
            <div className="mt-4 flex flex-col gap-3">
              <div className="flex items-center justify-between">
                <p className="text-[13px] font-semibold text-text-600">
                  {selectedPin.country ?? ''} {selectedPin.country ? '·' : ''} {selectedPin.region} · 기록{' '}
                  {selectedPin.records.length}건
                </p>
                <button
                  type="button"
                  onClick={() => setSelectedKey(null)}
                  className="text-[12px] text-text-400"
                >
                  닫기
                </button>
              </div>

              {selectedPin.records.map((r) => (
                <button
                  key={r.id}
                  type="button"
                  onClick={() => navigate(`/travel/record/${r.id}`)}
                  className="flex gap-3 rounded-2xl border border-gray-border p-3 text-left"
                  style={{ boxShadow: 'var(--shadow-card)' }}
                >
                  <div className="w-20 h-20 rounded-xl overflow-hidden shrink-0 bg-gray-100 flex items-center justify-center">
                    {r.thumbnailUrl ? (
                      <img src={r.thumbnailUrl} alt="" className="w-full h-full object-cover" />
                    ) : (
                      <span className="text-text-400 text-[22px]">🖼️</span>
                    )}
                  </div>
                  <div className="flex-1 min-w-0 flex flex-col justify-center gap-0.5">
                    <p className="text-[14px] font-semibold text-text-900 truncate">{r.title}</p>
                    <p className="text-[12px] text-text-400">
                      {r.start_date} ~ {r.end_date}
                    </p>
                    <p className="text-[12px] text-text-600 truncate">
                      {r.region} · {r.address}
                    </p>
                  </div>
                </button>
              ))}
            </div>
          )}
        </section>
      </main>

      <BottomNav />
    </div>
  );
}

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-gray-border px-3 py-3 text-center">
      <p className="text-[16px] font-bold text-text-900 leading-tight">{value}</p>
      <p className="text-[11px] text-text-400 mt-0.5">{label}</p>
    </div>
  );
}

function SubStat({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex-1 rounded-xl px-3 py-2.5 flex items-center justify-between" style={{ background: '#F1F5F9' }}>
      <span className="text-[12px] text-text-600 font-medium">{label}</span>
      <span className="text-[13px] font-bold text-text-900">{value}</span>
    </div>
  );
}
