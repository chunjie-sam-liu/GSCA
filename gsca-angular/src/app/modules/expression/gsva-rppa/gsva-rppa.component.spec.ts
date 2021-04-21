import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { GsvaRppaComponent } from './gsva-rppa.component';

describe('GsvaRppaComponent', () => {
  let component: GsvaRppaComponent;
  let fixture: ComponentFixture<GsvaRppaComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ GsvaRppaComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(GsvaRppaComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
