import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { GsdbComponent } from './gsdb.component';

describe('GsdbComponent', () => {
  let component: GsdbComponent;
  let fixture: ComponentFixture<GsdbComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ GsdbComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(GsdbComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
